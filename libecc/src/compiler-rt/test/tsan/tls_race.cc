// RUN: %clangxx_tsan -O1 %s -o %t && not %run %t 2>&1 | FileCheck %s
#include "test.h"

void *Thread(void *a) {
  barrier_wait(&barrier);
  *(int*)a = 43;
  return 0;
}

int main() {
  barrier_init(&barrier, 2);
  static __thread int Var = 42;
  pthread_t t;
  pthread_create(&t, 0, Thread, &Var);
  Var = 43;
  barrier_wait(&barrier);
  pthread_join(t, 0);
}

// CHECK: WARNING: ThreadSanitizer: data race
// CHECK:   Location is TLS of main thread.
