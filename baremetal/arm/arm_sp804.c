/* Initialize the ARM SP804 dual timer.
 */

#include "kernel.h"
#include "timer.h"
#include "arm_sp804.h"

static long resolution;                 // The clock divisor.
static long accumulated_error;          // Accumulated error in nanoseconds.
static void (*ns_handler)(void);        // The nanosecond timeout handler.
static void (*sec_handler)(void);       // The second timeout handler.

/* Get the timer resolution.
 */
long timer_getres(void)
{
    return resolution; 
}

/** Get the number of nanoseconds left in the current second.
 */
long timer_getns(void)
{
    return REG(Timer2Value) * resolution;
}

/** Set the nanosecond timeout function.
 * This function is called by the interrupt handler when the timer expires.
 */
void timer_set_ns_handler(void (*fn)(void))
{
    ns_handler = fn;
}

/** Set the second timeout function.
 * This function is called by the interrupt handler when the timer expires.
 */
void timer_set_sec_handler(void (*fn)(void))
{
    sec_handler = fn;
}

/** This is the second timer interupt handler.
 */
#include <stdio.h>
static void sec_interrupt()
{
    printf("sec_handler()\n");
    if (sec_handler) {
        sec_handler();
    }
}

typedef struct irq_handler
{
    int vector;                 // The interrupt vector, if any.
    int sources;                // The number of sources in this vector.
    struct {
        volatile uint32_t *irq_status;  // The interrupt status register.
        uint32_t irq_value;             // The interrupt active mask.
        volatile uint32_t *irq_clear;   // The interrupt clear register.
        uint32_t clear_value;           // The value to clear the interrupt.
        void (*handler)();              // The interrupt handler funcrion.
        void *unused1;
        void *unused2;
        void *unused3;
    } entries[];
} IRQHandler;

const IRQHandler timer_irq =
{
    .vector = 4,
    .sources = 2,
    {
        { ADR(Timer1MIS), TimerInt, ADR(Timer1IntClr), 0, NULL },
        { ADR(Timer2MIS), TimerInt, ADR(Timer2IntClr), 0, sec_interrupt },
    }
};

void identify_irq(void)
{
    printf("identify_irq()\n");
    for (int i = 0; i < timer_irq.sources; ++i) {
        if (*timer_irq.entries[i].irq_status & timer_irq.entries[i].irq_value) {
            *timer_irq.entries[i].irq_clear = timer_irq.entries[i].clear_value;
            if (timer_irq.entries[i].handler) {
                timer_irq.entries[i].handler();
            }
        }
    }
}

/** Set the next timeout.
 * @param value The timeout period in nanoseconds.
 */
void timer_set_timeout(long value)
{
    long timeout = value / resolution;
    long remainder = value % resolution;    // How many nanoseconds are we losing?
    timeout /= resolution;
    accumulated_error += remainder;         // Accumulate the error.
    if (accumulated_error >= resolution) {
        // Have accumulated enough error to bump the time.
        timeout += 1;
        accumulated_error -= resolution;
    }
}

static void init(void)
    __attribute__((__constructor__, __used__));

static void init(void)
{
    // Set up the timer.
    resolution = 1000000000 / (CLOCK / 1); 

    // Set up Timer 2 as the second timer.
    REG(Timer2BGLoad) = CLOCK;
    // Enable timer, 32 bit, Divide by 1 clock, periodic.
    REG(Timer2Control) = TimerEn|TimerSize|TimerMode|IntEnable;
}
