# ------------------------------------------------------------------
# This file is part of bzip2/libbzip2, a program and library for
# lossless, block-sorting data compression.
#
# bzip2/libbzip2 version 1.0.6 of 6 September 2010
# Copyright (C) 1996-2010 Julian Seward <jseward@bzip.org>
#
# Please read the WARNING, DISCLAIMER and PATENTS sections in the 
# README file.
#
# This program is released under the terms of the license contained
# in the file LICENSE.
# ------------------------------------------------------------------

SHELL=/bin/sh

# Get all linux configurations.
ELLCC = ../../..
LIBECC = $(ELLCC)/libecc
Configs := $(patsubst %.notyet,,$(shell cd $(LIBECC)/config; echo *-linux-*))

all: ecc $(Configs)

$(Configs):
	$(MAKE) clean
	$(MAKE) EXT=.$@ TARGET="-target $@" \
	        RUN=../../../bin/qemu-`$(ELLCC)/bin/ecc-getarch $@` bzip2all

ecc:
	$(MAKE) clean
	$(MAKE) bzip2all

OS=linux
CC=../../../bin/ecc
AR=../../../bin/ecc-ar
RANLIB=../../../bin/ecc-ranlib
LDFLAGS= 

BIGFILES=-D_FILE_OFFSET_BITS=64
#CFLAGS=-Wall -Winline -O2 $(BIGFILES)
CFLAGS=$(TARGET) -Wall -Winline -g $(BIGFILES) -D_XOPEN_SOURCE

# Where you want it installed when you do 'make install'
PREFIX=/usr/local


OBJS= blocksort.o  \
      huffman.o    \
      crctable.o   \
      randtable.o  \
      compress.o   \
      decompress.o \
      bzlib.o

bzip2all: libbz2.a bzip2$(EXT) bzip2recover test

bzip2$(EXT): libbz2.a bzip2.o
	$(CC) $(CFLAGS) $(LDFLAGS) -o bzip2$(EXT) bzip2.o -L. -lbz2

bzip2recover: bzip2recover.o
	$(CC) $(CFLAGS) $(LDFLAGS) -o bzip2recover bzip2recover.o

libbz2.a: $(OBJS)
	rm -f libbz2.a
	$(AR) cq libbz2.a $(OBJS)
	@if ( test -f $(RANLIB) -o -f /usr/bin/ranlib -o \
		-f /bin/ranlib -o -f /usr/ccs/bin/ranlib ) ; then \
		echo $(RANLIB) libbz2.a ; \
		$(RANLIB) libbz2.a ; \
	fi

check: test
test: bzip2$(EXT)
	@cat words1
	$(RUN) ./bzip2$(EXT) -1  < sample1.ref > sample1.rb2
	$(RUN) ./bzip2$(EXT) -2  < sample2.ref > sample2.rb2
	$(RUN) ./bzip2$(EXT) -3  < sample3.ref > sample3.rb2
	$(RUN) ./bzip2$(EXT) -d  < sample1.bz2 > sample1.tst
	$(RUN) ./bzip2$(EXT) -d  < sample2.bz2 > sample2.tst
	$(RUN) ./bzip2$(EXT) -ds < sample3.bz2 > sample3.tst
	cmp sample1.bz2 sample1.rb2 
	cmp sample2.bz2 sample2.rb2
	cmp sample3.bz2 sample3.rb2
	cmp sample1.tst sample1.ref
	cmp sample2.tst sample2.ref
	cmp sample3.tst sample3.ref
	@cat words3

install: bzip2 bzip2recover
	if ( test ! -d $(PREFIX)/bin ) ; then mkdir -p $(PREFIX)/bin ; fi
	if ( test ! -d $(PREFIX)/lib ) ; then mkdir -p $(PREFIX)/lib ; fi
	if ( test ! -d $(PREFIX)/man ) ; then mkdir -p $(PREFIX)/man ; fi
	if ( test ! -d $(PREFIX)/man/man1 ) ; then mkdir -p $(PREFIX)/man/man1 ; fi
	if ( test ! -d $(PREFIX)/include ) ; then mkdir -p $(PREFIX)/include ; fi
	cp -f bzip2 $(PREFIX)/bin/bzip2
	cp -f bzip2 $(PREFIX)/bin/bunzip2
	cp -f bzip2 $(PREFIX)/bin/bzcat
	cp -f bzip2recover $(PREFIX)/bin/bzip2recover
	chmod a+x $(PREFIX)/bin/bzip2
	chmod a+x $(PREFIX)/bin/bunzip2
	chmod a+x $(PREFIX)/bin/bzcat
	chmod a+x $(PREFIX)/bin/bzip2recover
	cp -f bzip2.1 $(PREFIX)/man/man1
	chmod a+r $(PREFIX)/man/man1/bzip2.1
	cp -f bzlib.h $(PREFIX)/include
	chmod a+r $(PREFIX)/include/bzlib.h
	cp -f libbz2.a $(PREFIX)/lib
	chmod a+r $(PREFIX)/lib/libbz2.a
	cp -f bzgrep $(PREFIX)/bin/bzgrep
	ln -s -f $(PREFIX)/bin/bzgrep $(PREFIX)/bin/bzegrep
	ln -s -f $(PREFIX)/bin/bzgrep $(PREFIX)/bin/bzfgrep
	chmod a+x $(PREFIX)/bin/bzgrep
	cp -f bzmore $(PREFIX)/bin/bzmore
	ln -s -f $(PREFIX)/bin/bzmore $(PREFIX)/bin/bzless
	chmod a+x $(PREFIX)/bin/bzmore
	cp -f bzdiff $(PREFIX)/bin/bzdiff
	ln -s -f $(PREFIX)/bin/bzdiff $(PREFIX)/bin/bzcmp
	chmod a+x $(PREFIX)/bin/bzdiff
	cp -f bzgrep.1 bzmore.1 bzdiff.1 $(PREFIX)/man/man1
	chmod a+r $(PREFIX)/man/man1/bzgrep.1
	chmod a+r $(PREFIX)/man/man1/bzmore.1
	chmod a+r $(PREFIX)/man/man1/bzdiff.1
	echo ".so man1/bzgrep.1" > $(PREFIX)/man/man1/bzegrep.1
	echo ".so man1/bzgrep.1" > $(PREFIX)/man/man1/bzfgrep.1
	echo ".so man1/bzmore.1" > $(PREFIX)/man/man1/bzless.1
	echo ".so man1/bzdiff.1" > $(PREFIX)/man/man1/bzcmp.1

clean: 
	rm -f *.o libbz2.a bzip2recover \
	sample1.rb2 sample2.rb2 sample3.rb2 \
	sample1.tst sample2.tst sample3.tst

veryclean: clean
	rm -f bzip2 bzip2.arm bzip2.i386 bzip2.microblaze bzip2.mips \
	      bzip2.nios2 bzip2.ppc bzip2.ppc64 bzip2.sparc bzip2.x86_64

blocksort.o: blocksort.c
	@cat words0
	$(CC) $(CFLAGS) -c blocksort.c
huffman.o: huffman.c
	$(CC) $(CFLAGS) -c huffman.c
crctable.o: crctable.c
	$(CC) $(CFLAGS) -c crctable.c
randtable.o: randtable.c
	$(CC) $(CFLAGS) -c randtable.c
compress.o: compress.c
	$(CC) $(CFLAGS) -c compress.c
decompress.o: decompress.c
	$(CC) $(CFLAGS) -c decompress.c
bzlib.o: bzlib.c
	$(CC) $(CFLAGS) -c bzlib.c
bzip2.o: bzip2.c
	$(CC) $(CFLAGS) -c bzip2.c
bzip2recover.o: bzip2recover.c
	$(CC) $(CFLAGS) -c bzip2recover.c


distclean: clean
	rm -f manual.ps manual.html manual.pdf

DISTNAME=bzip2-1.0.6
dist: check manual
	rm -f $(DISTNAME)
	ln -s -f . $(DISTNAME)
	tar cvf $(DISTNAME).tar \
	   $(DISTNAME)/blocksort.c \
	   $(DISTNAME)/huffman.c \
	   $(DISTNAME)/crctable.c \
	   $(DISTNAME)/randtable.c \
	   $(DISTNAME)/compress.c \
	   $(DISTNAME)/decompress.c \
	   $(DISTNAME)/bzlib.c \
	   $(DISTNAME)/bzip2.c \
	   $(DISTNAME)/bzip2recover.c \
	   $(DISTNAME)/bzlib.h \
	   $(DISTNAME)/bzlib_private.h \
	   $(DISTNAME)/Makefile \
	   $(DISTNAME)/LICENSE \
	   $(DISTNAME)/bzip2.1 \
	   $(DISTNAME)/bzip2.1.preformatted \
	   $(DISTNAME)/bzip2.txt \
	   $(DISTNAME)/words0 \
	   $(DISTNAME)/words1 \
	   $(DISTNAME)/words2 \
	   $(DISTNAME)/words3 \
	   $(DISTNAME)/sample1.ref \
	   $(DISTNAME)/sample2.ref \
	   $(DISTNAME)/sample3.ref \
	   $(DISTNAME)/sample1.bz2 \
	   $(DISTNAME)/sample2.bz2 \
	   $(DISTNAME)/sample3.bz2 \
	   $(DISTNAME)/dlltest.c \
	   $(DISTNAME)/manual.html \
	   $(DISTNAME)/manual.pdf \
	   $(DISTNAME)/manual.ps \
	   $(DISTNAME)/README \
	   $(DISTNAME)/README.COMPILATION.PROBLEMS \
	   $(DISTNAME)/README.XML.STUFF \
	   $(DISTNAME)/CHANGES \
	   $(DISTNAME)/libbz2.def \
	   $(DISTNAME)/libbz2.dsp \
	   $(DISTNAME)/dlltest.dsp \
	   $(DISTNAME)/makefile.msc \
	   $(DISTNAME)/unzcrash.c \
	   $(DISTNAME)/spewG.c \
	   $(DISTNAME)/mk251.c \
	   $(DISTNAME)/bzdiff \
	   $(DISTNAME)/bzdiff.1 \
	   $(DISTNAME)/bzmore \
	   $(DISTNAME)/bzmore.1 \
	   $(DISTNAME)/bzgrep \
	   $(DISTNAME)/bzgrep.1 \
	   $(DISTNAME)/Makefile-libbz2_so \
	   $(DISTNAME)/bz-common.xsl \
	   $(DISTNAME)/bz-fo.xsl \
	   $(DISTNAME)/bz-html.xsl \
	   $(DISTNAME)/bzip.css \
	   $(DISTNAME)/entities.xml \
	   $(DISTNAME)/manual.xml \
	   $(DISTNAME)/format.pl \
	   $(DISTNAME)/xmlproc.sh
	gzip -v $(DISTNAME).tar

# For rebuilding the manual from sources on my SuSE 9.1 box

MANUAL_SRCS= 	bz-common.xsl bz-fo.xsl bz-html.xsl bzip.css \
		entities.xml manual.xml 

manual: manual.html manual.ps manual.pdf

manual.ps: $(MANUAL_SRCS)
	./xmlproc.sh -ps manual.xml

manual.pdf: $(MANUAL_SRCS)
	./xmlproc.sh -pdf manual.xml

manual.html: $(MANUAL_SRCS)
	./xmlproc.sh -html manual.xml
