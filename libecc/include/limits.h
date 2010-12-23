#ifndef _LIMITS_H_
#define _LIMITS_H_

/** The maximum length of any multibyte character in any locale.
 */
#define MB_LEN_MAX 16
/** The number of bits in a character.
 * __CHAR_BIT__ is defined by the compiler.
 */
#define CHAR_BIT __CHAR_BIT__
/** The minimum value of a signed char.
 */
#define SCHAR_MIN (-__SCHAR_MAX__ - 1)
/** The maximum value of a signed char.
 * __SCHAR_MAX__ is defined by the compiler.
 */
#define SCHAR_MAX __SCHAR_MAX__
/** The maximum value of an unsigned char.
 * __UCHAR_MAX__ is defined by the compiler.
 */
#define UCHAR_MAX __UCHAR_MAX__
/** The minimum value of a char.
 */
#define CHAR_MIN (-__CHAR_MAX__ - 1)
/** The maximum value of a char.
 * __CHAR_MAX__ is defined by the compiler.
 */
#define CHAR_MAX __CHAR_MAX__
/** The minimum value of a signed short.
 */
#define SHRT_MIN (-__SHRT_MAX__ - 1)
/** The maximum value of a signed short.
 * __SHRT_MAX__ is defined by the compiler.
 */
#define SHRT_MAX __SHRT_MAX__
/** The maximum value of an unsigned short.
 * __USHRT_MAX__ is defined by the compiler.
 */
#define USHRT_MAX __USHRT_MAX__
/** The minimum value of a signed int.
 */
#define INT_MIN (-__INT_MAX__ - 1)
/** The maximum value of a signed int.
 * __INT_MAX__ is defined by the compiler.
 */
#define INT_MAX __INT_MAX__
/** The maximum value of an unsigned int.
 * __UINT_MAX__ is defined by the compiler.
 */
#define UINT_MAX __UINT_MAX__
/** The minimum value of a signed long.
 */
#define LONG_MIN (-__LONG_MAX__ - 1)
/** The maximum value of a signed long.
 * __LONG_MAX__ is defined by the compiler.
 */
#define LONG_MAX __LONG_MAX__
/** The maximum value of an unsigned long.
 * __ULONG_MAX__ is defined by the compiler.
 */
#define ULONG_MAX __ULONG_MAX__
/** The minimum value of a signed long long.
 */
#define LLONG_MIN (-__LLONG_MAX__ - 1)
/** The maximum value of a signed long long.
 * __LLONG_MAX__ is defined by the compiler.
 */
#define LLONG_MAX __LLONG_MAX__
/** The maximum value of an unsigned long long.
 * __ULLONG_MAX__ is defined by the compiler.
 */
#define ULLONG_MAX __ULLONG_MAX__

#endif
