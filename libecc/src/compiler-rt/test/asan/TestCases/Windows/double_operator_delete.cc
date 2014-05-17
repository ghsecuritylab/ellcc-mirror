// RUN: %clangxx_asan -O0 %s -Fe%t
// FIXME: 'cat' is needed due to PR19744.
// RUN: not %run %t 2>&1 | cat | FileCheck %s

#include <malloc.h>

int main() {
  int *x = new int[42];
  delete [] x;
  delete [] x;
// CHECK: AddressSanitizer: attempting double-free on [[ADDR:0x[0-9a-f]+]]
// CHECK-NEXT: {{#0 .* operator delete}}[]
// CHECK-NEXT: {{#1 .* main .*double_operator_delete.cc}}:[[@LINE-3]]
// CHECK: [[ADDR]] is located 0 bytes inside of 168-byte region
// CHECK-LABEL: freed by thread T0 here:
// CHECK-NEXT: {{#0 .* operator delete}}[]
// CHECK-NEXT: {{#1 .* main .*double_operator_delete.cc}}:[[@LINE-8]]
// CHECK-LABEL: previously allocated by thread T0 here:
// CHECK-NEXT: {{#0 .* operator new}}[]
// CHECK-NEXT: {{#1 .* main .*double_operator_delete.cc}}:[[@LINE-12]]
  return 0;
}

