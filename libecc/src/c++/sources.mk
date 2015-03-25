CXXFLAGS += -std=c++11 -D_XOPEN_SOURCE=700
VPATH := $(VPATH):$(SRCPATH)/c++/libcxx/src
SRCS += algorithm.cpp bind.cpp chrono.cpp condition_variable.cpp debug.cpp \
        exception.cpp future.cpp hash.cpp ios.cpp iostream.cpp locale.cpp \
        memory.cpp mutex.cpp new.cpp random.cpp regex.cpp stdexcept.cpp \
        string.cpp strstream.cpp system_error.cpp thread.cpp typeinfo.cpp \
        utility.cpp valarray.cpp

VPATH := $(VPATH):$(SRCPATH)/c++/libcxxabi/src
SRCS += abort_message.cpp cxa_aux_runtime.cpp cxa_default_handlers.cpp \
        cxa_demangle.cpp cxa_exception.cpp cxa_exception_storage.cpp \
        cxa_guard.cpp cxa_handlers.cpp cxa_new_delete.cpp cxa_personality.cpp \
        cxa_unexpected.cpp cxa_vector.cpp cxa_virtual.cpp cxx_exception.cpp \
        private_typeinfo.cpp cxx_stdexcept.cpp cxx_typeinfo.cpp

CFLAGS := -I$(SRCPATH)/c++/libcxxabi/include $(CFLAGS)
CXXFLAGS := -I$(SRCPATH)/c++/libcxxabi/include $(CXXFLAGS)
CXXFLAGS += -D_GNU_SOURCE -Ddl_info=Dl_info
CFLAGS += -DLIBCXXABI_USE_LLVM_UNWINDER=1
CXXFLAGS += -DLIBCXXABI_USE_LLVM_UNWINDER=1
VPATH := $(VPATH):$(SRCPATH)/c++/libcxxabi/src/Unwind
SRCS += libunwind.cpp UnwindLevel1.c UnwindLevel1-gcc-ext.c \
        UnwindRegistersRestore.S UnwindRegistersSave.S Unwind-EHABI.cpp
