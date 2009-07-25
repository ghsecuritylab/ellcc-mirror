#include <reent.h>
#include <wchar.h>
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>

size_t _wcrtomb_r(struct _reent *ptr, char *s, wchar_t wc, mbstate_t *ps)
{
  int retval = 0;
  char buf[10];

#ifdef _MB_CAPABLE
  if (ps == NULL)
    {
      _REENT_CHECK_MISC(ptr);
      ps = &(_REENT_WCRTOMB_STATE(ptr));
    }
#endif

  if (s == NULL)
    retval = _wctomb_r (ptr, buf, L'\0', ps);
  else
    retval = _wctomb_r (ptr, s, wc, ps);

  if (retval == -1)
    {
      ps->__count = 0;
      ptr->_errno = EILSEQ;
      return (size_t)(-1);
    }
  else
    return (size_t)retval;
}

#ifndef _REENT_ONLY
size_t wcrtomb(char *s, wchar_t wc, mbstate_t *ps)
{
  return _wcrtomb_r (_REENT, s, wc, ps);
}
#endif /* !_REENT_ONLY */
