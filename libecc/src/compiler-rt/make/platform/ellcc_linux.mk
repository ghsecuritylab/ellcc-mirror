Description := Static runtime libraries for ellcc/Linux.

###

PWD := $(shell pwd)
ELLCC := $(PWD)/../../..
LIBECC := $(ELLCC)/libecc
override CC := $(ELLCC)/bin/ecc
RANLIB   := $(ELLCC)/bin/ecc-ranlib
Arch := unknown
Configs := $(patsubst %.notyet,,$(shell cd $(LIBECC)/mkscripts/targets; echo *))
INCLUDES := $(foreach TARGET, $(Configs), $(LIBECC)/mkscripts/targets/$(TARGET)/setup.mk)
OS := linux
CFLAGS := -Wall -Werror -O3 -fomit-frame-pointer
-include $(INCLUDES)

CommonFunctions := GCDAProfiling $(CommonFunctions)

###

#FUNCTIONS.arm := $(call set_difference, $(CommonFunctions), clear_cache) \

FUNCTIONS.arm := $(CommonFunctions) \
		 aeabi_idivmod \
		 aeabi_uidivmod \
		 aeabi_ldivmod \
		 aeabi_uldivmod \
		 aeabi_memset \
		 aeabi_memmove \
		 aeabi_memcpy
#FUNCTIONS.armeb := $(call set_difference, $(CommonFunctions), clear_cache) \

FUNCTIONS.armeb := $(CommonFunctions) \
		 aeabi_idivmod \
		 aeabi_uidivmod \
		 aeabi_ldivmod \
		 aeabi_uldivmod \
		 aeabi_memset \
		 aeabi_memmove \
		 aeabi_memcpy
FUNCTIONS.i386 := $(CommonFunctions) $(ArchFunctions.i386)
FUNCTIONS.microblaze := $(CommonFunctions) $(ArchFunctions.microblaze)
FUNCTIONS.mips := $(CommonFunctions) $(ArchFunctions.mips)
FUNCTIONS.mipsel := $(CommonFunctions) $(ArchFunctions.mipsel)
FUNCTIONS.ppc := $(CommonFunctions) $(ArchFunctions.ppc)
# RICH: FUNCTIONS.ppc64 := $(CommonFunctions) $(ArchFunctions.ppc64)
FUNCTIONS.x86_64 := $(CommonFunctions) $(ArchFunctions.x86_64)

# Always use optimized variants.
OPTIMIZED := 1

# We don't need to use visibility hidden on Linux.
VISIBILITY_HIDDEN := 0
