/* A very simple non-interrupt driven console.
 */
#include <unistd.h>
#include <bits/syscall.h>       // For syscall numbers.
#include <sys/uio.h>            // For writev (used by printf()).
#include <sys/ioctl.h>
#include "kernel.h"
#include "arm_pl011.h"

static void send_char(int ch)
{
    while (*UARTFR & TXFF)
        continue;           // Wait while TX FIFO is full.
    *UARTDR = ch;
}

static int get_char(void)
{
    while (*UARTFR & RXFE)
        continue;           // Wait while RX FIFO is empty.
    return *UARTDR;
}

static int sys_ioctl(int fd, int request, ...)
{
    switch (request) {
    case TCGETS:
        return 0;       // Yes sir, we are a serial port.
    default:
        return -EINVAL;
    }
}

static ssize_t sys_write(int fd, const void *buf, size_t count)
{
    const unsigned char *s = buf;
    size_t i = 0;
    for ( ; i < count; ++i) {
        send_char(*s++);
    }
    return i;
}

static ssize_t sys_writev(int fd, const struct iovec *iov, int iovcount)
{
    ssize_t count = 0;
    for (int i = 0; i < iovcount; ++i) {
        ssize_t c = write(fd, iov[i].iov_base, iov[i].iov_len);
        if (c < 0) {
            count = c;
            break;
        }
        count += c;
    }
    return count;
}

static ssize_t sys_read(int fd, void *buf, size_t count)
{
    unsigned char *s = buf;
    size_t i = 0;
    for ( ; i < count; ) {
        int ch = get_char();    // Get the next character.
        ++i;                    // Count the character.
        switch (ch) {
            // Some simple line handling.
        case 0x7F:
        case '\b':
            // Simple backspace handling.
            --i;
            if (i) {
              send_char('\b');
              send_char(' ');
              send_char('\b');
              --s;
              --i;
            }
            break;
        case '\n':
        case '\r':
            // Make sure we send both a CR and LF.
            send_char(ch == '\r' ? '\n' : '\r');
            *s = '\n';          // and send a newline back.
            return i;           // This read is done.
        default:
            send_char(ch);      // Echo input.
            *s++ = ch;          // and send it back.
            break;
        }
    }
    return i;
}

static ssize_t sys_readv(int fd, const struct iovec *iov, int iovcount)
{
    ssize_t count = 0;
    for (int i = 0; i < iovcount; ++i) {
        ssize_t c = read(fd, iov[i].iov_base, iov[i].iov_len);
        if (c < 0) {
            count = c;
            break;
        }
        count += c;
    }
    return count;
}

static void init(void)
    __attribute__((__constructor__, __used__));

static void init(void)
{
    // Set up the simple console for polled serial I/O.
 
    // Set up a simple ioctl system call.
    __set_syscall(SYS_ioctl, sys_ioctl);
    // Set up a simple write system call.
    __set_syscall(SYS_write, sys_write);
    // Set up a simple writev system call.
    __set_syscall(SYS_writev, sys_writev);
    // Set up a simple read system call.
    __set_syscall(SYS_read, sys_read);
    // Set up a simple readv system call.
    __set_syscall(SYS_readv, sys_readv);
}
