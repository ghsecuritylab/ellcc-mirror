// RUN: %clangxx_tsan -O1 %s -o %t && not %run %t 2>&1 | FileCheck %s
#include "test.h"

int fds[2];

void *Thread1(void *x) {
  write(fds[1], "a", 1);
  barrier_wait(&barrier);
  return NULL;
}

void *Thread2(void *x) {
  barrier_wait(&barrier);
  close(fds[0]);
  close(fds[1]);
  return NULL;
}

int main() {
  barrier_init(&barrier, 2);
  pipe(fds);
  pthread_t t[2];
  pthread_create(&t[0], NULL, Thread1, NULL);
  pthread_create(&t[1], NULL, Thread2, NULL);
  pthread_join(t[0], NULL);
  pthread_join(t[1], NULL);
}

// CHECK: WARNING: ThreadSanitizer: data race
// CHECK:   Write of size 8
// CHECK:     #0 close
// CHECK:     #1 Thread2
// CHECK:   Previous read of size 8
// CHECK:     #0 write
// CHECK:     #1 Thread1


