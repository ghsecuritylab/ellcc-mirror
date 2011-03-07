#include <syscall.h>
#include <sys/types.h>
#include <unistd.h>

off_t lseek(int fd, off_t offset, int whence)
{
    return INLINE_SYSCALL(lseek, 3, fd, (long)offset, whence);  // RICH: Netbsd is 64 bit.
}
