; RUN: opt < %s -msan -msan-check-access-address=0 -S | FileCheck %s
; RUN: opt < %s -msan -msan-check-access-address=0 -msan-track-origins=1 -S | FileCheck -check-prefix=CHECK -check-prefix=CHECK-ORIGINS %s

target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

; Check the presence of __msan_init
; CHECK: @llvm.global_ctors {{.*}} @__msan_init

; Check the presence and the linkage type of __msan_track_origins and
; other interface symbols.
; CHECK-NOT: @__msan_track_origins
; CHECK-ORIGINS: @__msan_track_origins = weak_odr constant i32 1
; CHECK-NOT: @__msan_keep_going = weak_odr constant i32 0
; CHECK: @__msan_retval_tls = external thread_local(initialexec) global [{{.*}}]
; CHECK: @__msan_retval_origin_tls = external thread_local(initialexec) global i32
; CHECK: @__msan_param_tls = external thread_local(initialexec) global [{{.*}}]
; CHECK: @__msan_param_origin_tls = external thread_local(initialexec) global [{{.*}}]
; CHECK: @__msan_va_arg_tls = external thread_local(initialexec) global [{{.*}}]
; CHECK: @__msan_va_arg_overflow_size_tls = external thread_local(initialexec) global i64
; CHECK: @__msan_origin_tls = external thread_local(initialexec) global i32


; Check instrumentation of stores

define void @Store(i32* nocapture %p, i32 %x) nounwind uwtable sanitize_memory {
entry:
  store i32 %x, i32* %p, align 4
  ret void
}

; CHECK: @Store
; CHECK: load {{.*}} @__msan_param_tls
; CHECK-ORIGINS: load {{.*}} @__msan_param_origin_tls
; CHECK: store
; CHECK-ORIGINS: icmp
; CHECK-ORIGINS: br i1
; CHECK-ORIGINS: <label>
; CHECK-ORIGINS: store
; CHECK-ORIGINS: br label
; CHECK-ORIGINS: <label>
; CHECK: store
; CHECK: ret void


; Check instrumentation of aligned stores
; Shadow store has the same alignment as the original store; origin store
; does not specify explicit alignment.

define void @AlignedStore(i32* nocapture %p, i32 %x) nounwind uwtable sanitize_memory {
entry:
  store i32 %x, i32* %p, align 32
  ret void
}

; CHECK: @AlignedStore
; CHECK: load {{.*}} @__msan_param_tls
; CHECK-ORIGINS: load {{.*}} @__msan_param_origin_tls
; CHECK: store {{.*}} align 32
; CHECK-ORIGINS: icmp
; CHECK-ORIGINS: br i1
; CHECK-ORIGINS: <label>
; CHECK-ORIGINS: store {{.*}} align 32
; CHECK-ORIGINS: br label
; CHECK-ORIGINS: <label>
; CHECK: store {{.*}} align 32
; CHECK: ret void


; load followed by cmp: check that we load the shadow and call __msan_warning.
define void @LoadAndCmp(i32* nocapture %a) nounwind uwtable sanitize_memory {
entry:
  %0 = load i32* %a, align 4
  %tobool = icmp eq i32 %0, 0
  br i1 %tobool, label %if.end, label %if.then

if.then:                                          ; preds = %entry
  tail call void (...)* @foo() nounwind
  br label %if.end

if.end:                                           ; preds = %entry, %if.then
  ret void
}

declare void @foo(...)

; CHECK: @LoadAndCmp
; CHECK: = load
; CHECK: = load
; CHECK: call void @__msan_warning_noreturn()
; CHECK-NEXT: call void asm sideeffect
; CHECK-NEXT: unreachable
; CHECK: ret void

; Check that we store the shadow for the retval.
define i32 @ReturnInt() nounwind uwtable readnone sanitize_memory {
entry:
  ret i32 123
}

; CHECK: @ReturnInt
; CHECK: store i32 0,{{.*}}__msan_retval_tls
; CHECK: ret i32

; Check that we get the shadow for the retval.
define void @CopyRetVal(i32* nocapture %a) nounwind uwtable sanitize_memory {
entry:
  %call = tail call i32 @ReturnInt() nounwind
  store i32 %call, i32* %a, align 4
  ret void
}

; CHECK: @CopyRetVal
; CHECK: load{{.*}}__msan_retval_tls
; CHECK: store
; CHECK: store
; CHECK: ret void


; Check that we generate PHIs for shadow.
define void @FuncWithPhi(i32* nocapture %a, i32* %b, i32* nocapture %c) nounwind uwtable sanitize_memory {
entry:
  %tobool = icmp eq i32* %b, null
  br i1 %tobool, label %if.else, label %if.then

  if.then:                                          ; preds = %entry
  %0 = load i32* %b, align 4
  br label %if.end

  if.else:                                          ; preds = %entry
  %1 = load i32* %c, align 4
  br label %if.end

  if.end:                                           ; preds = %if.else, %if.then
  %t.0 = phi i32 [ %0, %if.then ], [ %1, %if.else ]
  store i32 %t.0, i32* %a, align 4
  ret void
}

; CHECK: @FuncWithPhi
; CHECK: = phi
; CHECK-NEXT: = phi
; CHECK: store
; CHECK: store
; CHECK: ret void

; Compute shadow for "x << 10"
define void @ShlConst(i32* nocapture %x) nounwind uwtable sanitize_memory {
entry:
  %0 = load i32* %x, align 4
  %1 = shl i32 %0, 10
  store i32 %1, i32* %x, align 4
  ret void
}

; CHECK: @ShlConst
; CHECK: = load
; CHECK: = load
; CHECK: shl
; CHECK: shl
; CHECK: store
; CHECK: store
; CHECK: ret void

; Compute shadow for "10 << x": it should have 'sext i1'.
define void @ShlNonConst(i32* nocapture %x) nounwind uwtable sanitize_memory {
entry:
  %0 = load i32* %x, align 4
  %1 = shl i32 10, %0
  store i32 %1, i32* %x, align 4
  ret void
}

; CHECK: @ShlNonConst
; CHECK: = load
; CHECK: = load
; CHECK: = sext i1
; CHECK: store
; CHECK: store
; CHECK: ret void

; SExt
define void @SExt(i32* nocapture %a, i16* nocapture %b) nounwind uwtable sanitize_memory {
entry:
  %0 = load i16* %b, align 2
  %1 = sext i16 %0 to i32
  store i32 %1, i32* %a, align 4
  ret void
}

; CHECK: @SExt
; CHECK: = load
; CHECK: = load
; CHECK: = sext
; CHECK: = sext
; CHECK: store
; CHECK: store
; CHECK: ret void


; memset
define void @MemSet(i8* nocapture %x) nounwind uwtable sanitize_memory {
entry:
  call void @llvm.memset.p0i8.i64(i8* %x, i8 42, i64 10, i32 1, i1 false)
  ret void
}

declare void @llvm.memset.p0i8.i64(i8* nocapture, i8, i64, i32, i1) nounwind

; CHECK: @MemSet
; CHECK: call i8* @__msan_memset
; CHECK: ret void


; memcpy
define void @MemCpy(i8* nocapture %x, i8* nocapture %y) nounwind uwtable sanitize_memory {
entry:
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* %x, i8* %y, i64 10, i32 1, i1 false)
  ret void
}

declare void @llvm.memcpy.p0i8.p0i8.i64(i8* nocapture, i8* nocapture, i64, i32, i1) nounwind

; CHECK: @MemCpy
; CHECK: call i8* @__msan_memcpy
; CHECK: ret void


; memmove is lowered to a call
define void @MemMove(i8* nocapture %x, i8* nocapture %y) nounwind uwtable sanitize_memory {
entry:
  call void @llvm.memmove.p0i8.p0i8.i64(i8* %x, i8* %y, i64 10, i32 1, i1 false)
  ret void
}

declare void @llvm.memmove.p0i8.p0i8.i64(i8* nocapture, i8* nocapture, i64, i32, i1) nounwind

; CHECK: @MemMove
; CHECK: call i8* @__msan_memmove
; CHECK: ret void


; Check that we propagate shadow for "select"

define i32 @Select(i32 %a, i32 %b, i1 %c) nounwind uwtable readnone sanitize_memory {
entry:
  %cond = select i1 %c, i32 %a, i32 %b
  ret i32 %cond
}

; CHECK: @Select
; CHECK: select
; CHECK-NEXT: sext i1 {{.*}} to i32
; CHECK-NEXT: or i32
; CHECK-NEXT: select
; CHECK-ORIGINS: select
; CHECK-ORIGINS: select
; CHECK: select
; CHECK: ret i32


; Check that we propagate origin for "select" with vector condition.
; Select condition is flattened to i1, which is then used to select one of the
; argument origins.

define <8 x i16> @SelectVector(<8 x i16> %a, <8 x i16> %b, <8 x i1> %c) nounwind uwtable readnone sanitize_memory {
entry:
  %cond = select <8 x i1> %c, <8 x i16> %a, <8 x i16> %b
  ret <8 x i16> %cond
}

; CHECK: @SelectVector
; CHECK: select <8 x i1>
; CHECK-NEXT: sext <8 x i1> {{.*}} to <8 x i16>
; CHECK-NEXT: or <8 x i16>
; CHECK-ORIGINS: bitcast <8 x i1> {{.*}} to i8
; CHECK-ORIGINS: icmp ne i8 {{.*}}, 0
; CHECK-ORIGINS: bitcast <8 x i1> {{.*}} to i8
; CHECK-ORIGINS: icmp ne i8 {{.*}}, 0
; CHECK-ORIGINS: select i1
; CHECK-ORIGINS: select i1
; CHECK: select <8 x i1>
; CHECK: ret <8 x i16>



; Check that we propagate origin for "select" with scalar condition and vector
; arguments. Select condition shadow is sign-extended to the vector type and
; mixed into the result shadow.

define <8 x i16> @SelectVector2(<8 x i16> %a, <8 x i16> %b, i1 %c) nounwind uwtable readnone sanitize_memory {
entry:
  %cond = select i1 %c, <8 x i16> %a, <8 x i16> %b
  ret <8 x i16> %cond
}

; CHECK: @SelectVector2
; CHECK: select i1
; CHECK: sext i1 {{.*}} to i128
; CHECK: bitcast i128 {{.*}} to <8 x i16>
; CHECK: or <8 x i16>
; CHECK-ORIGINS: select i1
; CHECK-ORIGINS: select i1
; CHECK: select i1
; CHECK: ret <8 x i16>


define { i64, i64 } @SelectStruct(i1 zeroext %x, { i64, i64 } %a, { i64, i64 } %b) readnone sanitize_memory {
entry:
  %c = select i1 %x, { i64, i64 } %a, { i64, i64 } %b
  ret { i64, i64 } %c
}

; CHECK: @SelectStruct
; CHECK: select i1 {{.*}}, { i64, i64 }
; CHECK-NEXT: select i1 {{.*}}, { i64, i64 } { i64 -1, i64 -1 }, { i64, i64 }
; CHECK-ORIGINS: select i1
; CHECK-ORIGINS: select i1
; CHECK-NEXT: select i1 {{.*}}, { i64, i64 }
; CHECK: ret { i64, i64 }


define i8* @IntToPtr(i64 %x) nounwind uwtable readnone sanitize_memory {
entry:
  %0 = inttoptr i64 %x to i8*
  ret i8* %0
}

; CHECK: @IntToPtr
; CHECK: load i64*{{.*}}__msan_param_tls
; CHECK-ORIGINS-NEXT: load i32*{{.*}}__msan_param_origin_tls
; CHECK-NEXT: inttoptr
; CHECK-NEXT: store i64{{.*}}__msan_retval_tls
; CHECK: ret i8*


define i8* @IntToPtr_ZExt(i16 %x) nounwind uwtable readnone sanitize_memory {
entry:
  %0 = inttoptr i16 %x to i8*
  ret i8* %0
}

; CHECK: @IntToPtr_ZExt
; CHECK: load i16*{{.*}}__msan_param_tls
; CHECK: zext
; CHECK-NEXT: inttoptr
; CHECK-NEXT: store i64{{.*}}__msan_retval_tls
; CHECK: ret i8*


; Check that we insert exactly one check on udiv
; (2nd arg shadow is checked, 1st arg shadow is propagated)

define i32 @Div(i32 %a, i32 %b) nounwind uwtable readnone sanitize_memory {
entry:
  %div = udiv i32 %a, %b
  ret i32 %div
}

; CHECK: @Div
; CHECK: icmp
; CHECK: call void @__msan_warning
; CHECK-NOT: icmp
; CHECK: udiv
; CHECK-NOT: icmp
; CHECK: ret i32


; Check that we propagate shadow for x<0, x>=0, etc (i.e. sign bit tests)

define zeroext i1 @ICmpSLT(i32 %x) nounwind uwtable readnone sanitize_memory {
  %1 = icmp slt i32 %x, 0
  ret i1 %1
}

; CHECK: @ICmpSLT
; CHECK: icmp slt
; CHECK-NOT: call void @__msan_warning
; CHECK: icmp slt
; CHECK-NOT: call void @__msan_warning
; CHECK: ret i1

define zeroext i1 @ICmpSGE(i32 %x) nounwind uwtable readnone sanitize_memory {
  %1 = icmp sge i32 %x, 0
  ret i1 %1
}

; CHECK: @ICmpSGE
; CHECK: icmp slt
; CHECK-NOT: call void @__msan_warning
; CHECK: icmp sge
; CHECK-NOT: call void @__msan_warning
; CHECK: ret i1

define zeroext i1 @ICmpSGT(i32 %x) nounwind uwtable readnone sanitize_memory {
  %1 = icmp sgt i32 0, %x
  ret i1 %1
}

; CHECK: @ICmpSGT
; CHECK: icmp slt
; CHECK-NOT: call void @__msan_warning
; CHECK: icmp sgt
; CHECK-NOT: call void @__msan_warning
; CHECK: ret i1

define zeroext i1 @ICmpSLE(i32 %x) nounwind uwtable readnone sanitize_memory {
  %1 = icmp sle i32 0, %x
  ret i1 %1
}

; CHECK: @ICmpSLE
; CHECK: icmp slt
; CHECK-NOT: call void @__msan_warning
; CHECK: icmp sle
; CHECK-NOT: call void @__msan_warning
; CHECK: ret i1


; Check that we propagate shadow for x<0, x>=0, etc (i.e. sign bit tests)
; of the vector arguments.

define <2 x i1> @ICmpSLT_vector(<2 x i32*> %x) nounwind uwtable readnone sanitize_memory {
  %1 = icmp slt <2 x i32*> %x, zeroinitializer
  ret <2 x i1> %1
}

; CHECK: @ICmpSLT_vector
; CHECK: icmp slt <2 x i64>
; CHECK-NOT: call void @__msan_warning
; CHECK: icmp slt <2 x i32*>
; CHECK-NOT: call void @__msan_warning
; CHECK: ret <2 x i1>


; Check that we propagate shadow for unsigned relational comparisons with
; constants

define zeroext i1 @ICmpUGTConst(i32 %x) nounwind uwtable readnone sanitize_memory {
entry:
  %cmp = icmp ugt i32 %x, 7
  ret i1 %cmp
}

; CHECK: @ICmpUGTConst
; CHECK: icmp ugt i32
; CHECK-NOT: call void @__msan_warning
; CHECK: icmp ugt i32
; CHECK-NOT: call void @__msan_warning
; CHECK: icmp ugt i32
; CHECK-NOT: call void @__msan_warning
; CHECK: ret i1


; Check that loads of shadow have the same aligment as the original loads.
; Check that loads of origin have the aligment of max(4, original alignment).

define i32 @ShadowLoadAlignmentLarge() nounwind uwtable sanitize_memory {
  %y = alloca i32, align 64
  %1 = load volatile i32* %y, align 64
  ret i32 %1
}

; CHECK: @ShadowLoadAlignmentLarge
; CHECK: load volatile i32* {{.*}} align 64
; CHECK: load i32* {{.*}} align 64
; CHECK: ret i32

define i32 @ShadowLoadAlignmentSmall() nounwind uwtable sanitize_memory {
  %y = alloca i32, align 2
  %1 = load volatile i32* %y, align 2
  ret i32 %1
}

; CHECK: @ShadowLoadAlignmentSmall
; CHECK: load volatile i32* {{.*}} align 2
; CHECK: load i32* {{.*}} align 2
; CHECK-ORIGINS: load i32* {{.*}} align 4
; CHECK: ret i32


; Test vector manipulation instructions.
; Check that the same bit manipulation is applied to the shadow values.
; Check that there is a zero test of the shadow of %idx argument, where present.

define i32 @ExtractElement(<4 x i32> %vec, i32 %idx) sanitize_memory {
  %x = extractelement <4 x i32> %vec, i32 %idx
  ret i32 %x
}

; CHECK: @ExtractElement
; CHECK: extractelement
; CHECK: call void @__msan_warning
; CHECK: extractelement
; CHECK: ret i32

define <4 x i32> @InsertElement(<4 x i32> %vec, i32 %idx, i32 %x) sanitize_memory {
  %vec1 = insertelement <4 x i32> %vec, i32 %x, i32 %idx
  ret <4 x i32> %vec1
}

; CHECK: @InsertElement
; CHECK: insertelement
; CHECK: call void @__msan_warning
; CHECK: insertelement
; CHECK: ret <4 x i32>

define <4 x i32> @ShuffleVector(<4 x i32> %vec, <4 x i32> %vec1) sanitize_memory {
  %vec2 = shufflevector <4 x i32> %vec, <4 x i32> %vec1,
                        <4 x i32> <i32 0, i32 4, i32 1, i32 5>
  ret <4 x i32> %vec2
}

; CHECK: @ShuffleVector
; CHECK: shufflevector
; CHECK-NOT: call void @__msan_warning
; CHECK: shufflevector
; CHECK: ret <4 x i32>


; Test bswap intrinsic instrumentation
define i32 @BSwap(i32 %x) nounwind uwtable readnone sanitize_memory {
  %y = tail call i32 @llvm.bswap.i32(i32 %x)
  ret i32 %y
}

declare i32 @llvm.bswap.i32(i32) nounwind readnone

; CHECK: @BSwap
; CHECK-NOT: call void @__msan_warning
; CHECK: @llvm.bswap.i32
; CHECK-NOT: call void @__msan_warning
; CHECK: @llvm.bswap.i32
; CHECK-NOT: call void @__msan_warning
; CHECK: ret i32


; Store intrinsic.

define void @StoreIntrinsic(i8* %p, <4 x float> %x) nounwind uwtable sanitize_memory {
  call void @llvm.x86.sse.storeu.ps(i8* %p, <4 x float> %x)
  ret void
}

declare void @llvm.x86.sse.storeu.ps(i8*, <4 x float>) nounwind

; CHECK: @StoreIntrinsic
; CHECK-NOT: br
; CHECK-NOT: = or
; CHECK: store <4 x i32> {{.*}} align 1
; CHECK: call void @llvm.x86.sse.storeu.ps
; CHECK: ret void


; Load intrinsic.

define <16 x i8> @LoadIntrinsic(i8* %p) nounwind uwtable sanitize_memory {
  %call = call <16 x i8> @llvm.x86.sse3.ldu.dq(i8* %p)
  ret <16 x i8> %call
}

declare <16 x i8> @llvm.x86.sse3.ldu.dq(i8* %p) nounwind

; CHECK: @LoadIntrinsic
; CHECK: load <16 x i8>* {{.*}} align 1
; CHECK-ORIGINS: [[ORIGIN:%[01-9a-z]+]] = load i32* {{.*}}
; CHECK-NOT: br
; CHECK-NOT: = or
; CHECK: call <16 x i8> @llvm.x86.sse3.ldu.dq
; CHECK: store <16 x i8> {{.*}} @__msan_retval_tls
; CHECK-ORIGINS: store i32 {{.*}}[[ORIGIN]], i32* @__msan_retval_origin_tls
; CHECK: ret <16 x i8>


; Simple NoMem intrinsic
; Check that shadow is OR'ed, and origin is Select'ed
; And no shadow checks!

define <8 x i16> @Paddsw128(<8 x i16> %a, <8 x i16> %b) nounwind uwtable sanitize_memory {
  %call = call <8 x i16> @llvm.x86.sse2.padds.w(<8 x i16> %a, <8 x i16> %b)
  ret <8 x i16> %call
}

declare <8 x i16> @llvm.x86.sse2.padds.w(<8 x i16> %a, <8 x i16> %b) nounwind

; CHECK: @Paddsw128
; CHECK-NEXT: load <8 x i16>* {{.*}} @__msan_param_tls
; CHECK-ORIGINS: load i32* {{.*}} @__msan_param_origin_tls
; CHECK-NEXT: load <8 x i16>* {{.*}} @__msan_param_tls
; CHECK-ORIGINS: load i32* {{.*}} @__msan_param_origin_tls
; CHECK-NEXT: = or <8 x i16>
; CHECK-ORIGINS: = bitcast <8 x i16> {{.*}} to i128
; CHECK-ORIGINS-NEXT: = icmp ne i128 {{.*}}, 0
; CHECK-ORIGINS-NEXT: = select i1 {{.*}}, i32 {{.*}}, i32
; CHECK-NEXT: call <8 x i16> @llvm.x86.sse2.padds.w
; CHECK-NEXT: store <8 x i16> {{.*}} @__msan_retval_tls
; CHECK-ORIGINS: store i32 {{.*}} @__msan_retval_origin_tls
; CHECK-NEXT: ret <8 x i16>


; Test handling of vectors of pointers.
; Check that shadow of such vector is a vector of integers.

define <8 x i8*> @VectorOfPointers(<8 x i8*>* %p) nounwind uwtable sanitize_memory {
  %x = load <8 x i8*>* %p
  ret <8 x i8*> %x
}

; CHECK: @VectorOfPointers
; CHECK: load <8 x i8*>*
; CHECK: load <8 x i64>*
; CHECK: store <8 x i64> {{.*}} @__msan_retval_tls
; CHECK: ret <8 x i8*>

; Test handling of va_copy.

declare void @llvm.va_copy(i8*, i8*) nounwind

define void @VACopy(i8* %p1, i8* %p2) nounwind uwtable sanitize_memory {
  call void @llvm.va_copy(i8* %p1, i8* %p2) nounwind
  ret void
}

; CHECK: @VACopy
; CHECK: call void @llvm.memset.p0i8.i64({{.*}}, i8 0, i64 24, i32 8, i1 false)
; CHECK: ret void


; Test that va_start instrumentation does not use va_arg_tls*.
; It should work with a local stack copy instead.

%struct.__va_list_tag = type { i32, i32, i8*, i8* }
declare void @llvm.va_start(i8*) nounwind

; Function Attrs: nounwind uwtable
define void @VAStart(i32 %x, ...) {
entry:
  %x.addr = alloca i32, align 4
  %va = alloca [1 x %struct.__va_list_tag], align 16
  store i32 %x, i32* %x.addr, align 4
  %arraydecay = getelementptr inbounds [1 x %struct.__va_list_tag]* %va, i32 0, i32 0
  %arraydecay1 = bitcast %struct.__va_list_tag* %arraydecay to i8*
  call void @llvm.va_start(i8* %arraydecay1)
  ret void
}

; CHECK: @VAStart
; CHECK: call void @llvm.va_start
; CHECK-NOT: @__msan_va_arg_tls
; CHECK-NOT: @__msan_va_arg_overflow_size_tls
; CHECK: ret void


; Test handling of volatile stores.
; Check that MemorySanitizer does not add a check of the value being stored.

define void @VolatileStore(i32* nocapture %p, i32 %x) nounwind uwtable sanitize_memory {
entry:
  store volatile i32 %x, i32* %p, align 4
  ret void
}

; CHECK: @VolatileStore
; CHECK-NOT: @__msan_warning
; CHECK: ret void


; Test that checks are omitted but shadow propagation is kept if
; sanitize_memory attribute is missing.

define i32 @NoSanitizeMemory(i32 %x) uwtable {
entry:
  %tobool = icmp eq i32 %x, 0
  br i1 %tobool, label %if.end, label %if.then

if.then:                                          ; preds = %entry
  tail call void @bar()
  br label %if.end

if.end:                                           ; preds = %entry, %if.then
  ret i32 %x
}

declare void @bar()

; CHECK: @NoSanitizeMemory
; CHECK-NOT: @__msan_warning
; CHECK: load i32* {{.*}} @__msan_param_tls
; CHECK-NOT: @__msan_warning
; CHECK: store {{.*}} @__msan_retval_tls
; CHECK-NOT: @__msan_warning
; CHECK: ret i32


; Test that stack allocations are unpoisoned in functions missing
; sanitize_memory attribute

define i32 @NoSanitizeMemoryAlloca() {
entry:
  %p = alloca i32, align 4
  %x = call i32 @NoSanitizeMemoryAllocaHelper(i32* %p)
  ret i32 %x
}

declare i32 @NoSanitizeMemoryAllocaHelper(i32* %p)

; CHECK: @NoSanitizeMemoryAlloca
; CHECK: call void @llvm.memset.p0i8.i64(i8* {{.*}}, i8 0, i64 4, i32 4, i1 false)
; CHECK: call i32 @NoSanitizeMemoryAllocaHelper(i32*
; CHECK: ret i32


; Test that undef is unpoisoned in functions missing
; sanitize_memory attribute

define i32 @NoSanitizeMemoryUndef() {
entry:
  %x = call i32 @NoSanitizeMemoryUndefHelper(i32 undef)
  ret i32 %x
}

declare i32 @NoSanitizeMemoryUndefHelper(i32 %x)

; CHECK: @NoSanitizeMemoryAlloca
; CHECK: store i32 0, i32* {{.*}} @__msan_param_tls
; CHECK: call i32 @NoSanitizeMemoryUndefHelper(i32 undef)
; CHECK: ret i32


; Test argument shadow alignment

define <2 x i64> @ArgumentShadowAlignment(i64 %a, <2 x i64> %b) sanitize_memory {
entry:
  ret <2 x i64> %b
}

; CHECK: @ArgumentShadowAlignment
; CHECK: load <2 x i64>* {{.*}} @__msan_param_tls {{.*}}, align 8
; CHECK: store <2 x i64> {{.*}} @__msan_retval_tls {{.*}}, align 8
; CHECK: ret <2 x i64>


; Test origin propagation for insertvalue

define { i64, i32 } @make_pair_64_32(i64 %x, i32 %y) sanitize_memory {
entry:
  %a = insertvalue { i64, i32 } undef, i64 %x, 0
  %b = insertvalue { i64, i32 } %a, i32 %y, 1
  ret { i64, i32 } %b
}

; CHECK-ORIGINS: @make_pair_64_32
; First element shadow
; CHECK-ORIGINS: insertvalue { i64, i32 } { i64 -1, i32 -1 }, i64 {{.*}}, 0
; First element origin
; CHECK-ORIGINS: icmp ne i64
; CHECK-ORIGINS: select i1
; First element app value
; CHECK-ORIGINS: insertvalue { i64, i32 } undef, i64 {{.*}}, 0
; Second element shadow
; CHECK-ORIGINS: insertvalue { i64, i32 } {{.*}}, i32 {{.*}}, 1
; Second element origin
; CHECK-ORIGINS: icmp ne i32
; CHECK-ORIGINS: select i1
; Second element app value
; CHECK-ORIGINS: insertvalue { i64, i32 } {{.*}}, i32 {{.*}}, 1
; CHECK-ORIGINS: ret { i64, i32 }


; Test shadow propagation for aggregates passed through ellipsis.

%struct.StructByVal = type { i32, i32, i32, i32 }

declare void @VAArgStructFn(i32 %guard, ...)

define void @VAArgStruct(%struct.StructByVal* nocapture %s) sanitize_memory {
entry:
  %agg.tmp2 = alloca %struct.StructByVal, align 8
  %0 = bitcast %struct.StructByVal* %s to i8*
  %agg.tmp.sroa.0.0..sroa_cast = bitcast %struct.StructByVal* %s to i64*
  %agg.tmp.sroa.0.0.copyload = load i64* %agg.tmp.sroa.0.0..sroa_cast, align 4
  %agg.tmp.sroa.2.0..sroa_idx = getelementptr inbounds %struct.StructByVal* %s, i64 0, i32 2
  %agg.tmp.sroa.2.0..sroa_cast = bitcast i32* %agg.tmp.sroa.2.0..sroa_idx to i64*
  %agg.tmp.sroa.2.0.copyload = load i64* %agg.tmp.sroa.2.0..sroa_cast, align 4
  %1 = bitcast %struct.StructByVal* %agg.tmp2 to i8*
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* %0, i64 16, i32 4, i1 false)
  call void (i32, ...)* @VAArgStructFn(i32 undef, i64 %agg.tmp.sroa.0.0.copyload, i64 %agg.tmp.sroa.2.0.copyload, i64 %agg.tmp.sroa.0.0.copyload, i64 %agg.tmp.sroa.2.0.copyload, %struct.StructByVal* byval align 8 %agg.tmp2)
  ret void
}

; "undef" and the first 2 structs go to general purpose registers;
; the third struct goes to the overflow area byval

; CHECK: @VAArgStruct
; undef
; CHECK: store i32 -1, i32* {{.*}}@__msan_va_arg_tls {{.*}}, align 8
; first struct through general purpose registers
; CHECK: store i64 {{.*}}, i64* {{.*}}@__msan_va_arg_tls{{.*}}, i64 8){{.*}}, align 8
; CHECK: store i64 {{.*}}, i64* {{.*}}@__msan_va_arg_tls{{.*}}, i64 16){{.*}}, align 8
; second struct through general purpose registers
; CHECK: store i64 {{.*}}, i64* {{.*}}@__msan_va_arg_tls{{.*}}, i64 24){{.*}}, align 8
; CHECK: store i64 {{.*}}, i64* {{.*}}@__msan_va_arg_tls{{.*}}, i64 32){{.*}}, align 8
; third struct through the overflow area byval
; CHECK: ptrtoint %struct.StructByVal* {{.*}} to i64
; CHECK: bitcast { i32, i32, i32, i32 }* {{.*}}@__msan_va_arg_tls {{.*}}, i64 176
; CHECK: call void @llvm.memcpy.p0i8.p0i8.i64
; CHECK: store i64 16, i64* @__msan_va_arg_overflow_size_tls
; CHECK: call void (i32, ...)* @VAArgStructFn
; CHECK: ret void
