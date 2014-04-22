/** Kernel definitions.
 */

#ifndef _kernel_h_
#define _kernel_h_

#include <stdint.h>
#include <stddef.h>
#include "arm.h"

#ifndef NULL
#define NULL 0
#endif

/** Set a system call handler.
 * @param nr The system call number.
 * @param fn The system call handling function.
 * @return 0 on success, -1 on  error.
 */
int __set_syscall(int nr, void *fn);

/** Set up a new context.
 * @param savearea Where to put the finished stack pointer.
 * @param entry The context entry point (0 if return to caller).
 * @param mode The context execution mode.
 * @param arg1 The first argument to the entry point.
 * @param arg2 The second argument to the entry point.
 * @return 1 to indicate non-clone, else arg1.
 */
typedef long (*ThreadFunction)(long, long);


int __new_context(Context **savearea, ThreadFunction entry, int mode,
                  long arg1, long arg2);

// sync.h
typedef struct lock
{
    char lock;
    int level;
} Lock;

static inline void lock_aquire(Lock *lock)
{
    lock->level = splhigh();
    while(!__atomic_test_and_set(&lock->lock, __ATOMIC_SEQ_CST))
        continue;
}

static inline void lock_release(Lock *lock)
{
    __atomic_clear(&lock->lock, __ATOMIC_SEQ_CST);
    splx(lock->level);
}

// queue.h
typedef struct entry
{
    struct entry *next;         // The next entry in the queue.
    size_t size;                // The entry size.
} Entry;

struct thread;
typedef struct queue
{
    Entry *head;                // The head of the queue.
    Entry *tail;                // The tail of the queue.
    struct thread *waiter;      // Any threads waiting on the queue.
    Lock lock;
} Queue;

void send_queue(Queue *queue, Entry *entry);
Entry *get_queue_nowait(Queue *queue);
Entry *get_queue(Queue *queue);

// thread.h
typedef struct thread
{
    // The saved_sp field must be first in the thread struct.
    Context *saved_sp;          // The thread's saved stack pointer.
    struct thread *next;        // Next thread in any list.
} Thread;

/** Create a new thread and make it run-able.
 * @param entry The thread entry point.
 * @param stack A preallocated stack, or NULL.
 * @param size The stack size.
 * @param arg1 The first parameter.
 * @param arg2 The second parameter.
 * @param status A place to put any generated errno values.
 * @return The thread ID.
 */
Thread *new_thread(ThreadFunction entry, void *stack, size_t size, 
                   long arg1, long arg2, long r5, long r6, int *status);

// message.h
typedef struct message
{
    Entry entry;                // Next message in any list.
    int code;                   // The message code.
} Message;

static inline void send_message(Queue *queue, Message *message)
{
    send_queue(queue, (Entry *)message);
}

static inline Message *get_message(Queue *queue)
{
    return (Message *)get_queue(queue);
}

static inline Message *get_message_nowait(Queue *queue)
{
    return (Message *)get_queue_nowait(queue);
}

/** Switch to a new context.
 * @param to The new context.
 * @param from A place to store the current context.
 */
void __switch(Context *to, Context **from, void (*)(Lock *), Lock *);

#endif // _kernel_h_
