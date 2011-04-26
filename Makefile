# Makefile

include config.mak

all: default

SRCS = obe.c \
       input/lavc.c input/lavf/lavf.c \
       filters/video/video.c \
       encoders/video/avc/x264.c \
       mux/ts/ts.c \
       output/network.c output/rtp/rtp.c output/udp/udp.c

SRCCXX =

SRCCLI = obecli.c

SRCSO =

CONFIG := $(shell cat config.h)

# Optional module sources
ifneq ($(findstring HAVE_LIBTWOLAME 1, $(CONFIG)),)
SRCS += encoders/audio/mp2/twolame.c
endif

ifneq ($(findstring HAVE_DECKLINK 1, $(CONFIG)),)
SRCCXX += input/sdi/decklink/decklink.cpp
endif

OBJS = $(SRCS:%.c=%.o)
OBJSCXX = $(SRCCXX:%.cpp=%.o)
OBJCLI = $(SRCCLI:%.c=%.o)
OBJSO = $(SRCSO:%.c=%.o)
DEP  = depend

.PHONY: all default fprofiled clean distclean install uninstall dox test testclean

default: $(DEP) obecli$(EXE)

libobe.a: .depend $(OBJS) $(OBJSCXX)
	$(AR) rc libobe.a $(OBJS) $(OBJSCXX)
	$(RANLIB) libobe.a

$(SONAME): .depend $(OBJS) $(OBJSCXX) $(OBJSO)
	$(CC) -shared -o $@ $(OBJS) $(OBJSO) $(SOFLAGS) $(LDFLAGS)

obecli$(EXE): $(OBJCLI) libobe.a
	$(CC) -o $@ $+ $(LDFLAGSCLI) $(LDFLAGS)

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -o $@ $<

.depend: config.mak
	@rm -f .depend
	@$(foreach SRC, $(SRCS) $(SRCCLI) $(SRCSO), $(CC) $(CFLAGS) $(SRC) -MT $(SRC:%.c=%.o) -MM -g0 1>> .depend;)
	@$(foreach SRC, $(SRCCXX), $(CXX) $(CXXFLAGS) $(SRC) -MT $(SRCCXX:%.cpp=%.o) -MM -g0 1>> .depend;)

config.mak:
	./configure

depend: .depend
ifneq ($(wildcard .depend),)
include .depend
endif

SRC2 = $(SRCS) $(SRCCLI)

clean:
	rm -f $(OBJS) $(OBJSCXX) $(OBJCLI) $(OBJSO) $(SONAME) *.a obe obe.exe .depend TAGS
	rm -f $(SRC2:%.c=%.gcda) $(SRC2:%.c=%.gcno)
	- sed -e 's/ *-fprofile-\(generate\|use\)//g' config.mak > config.mak2 && mv config.mak2 config.mak

distclean: clean
	rm -f config.mak config.h config.log obe.pc
	rm -rf test/

install: obecli$(EXE) $(SONAME)
	install -d $(DESTDIR)$(bindir)
	install -d $(DESTDIR)$(includedir)
	install -d $(DESTDIR)$(libdir)
	install -d $(DESTDIR)$(libdir)/pkgconfig
	install -m 644 libobe.a $(DESTDIR)$(libdir)
	install -m 644 obe.pc $(DESTDIR)$(libdir)/pkgconfig
	install obecli$(EXE) $(DESTDIR)$(bindir)
	$(RANLIB) $(DESTDIR)$(libdir)/libobe.a
ifeq ($(SYS),MINGW)
	$(if $(SONAME), install -m 755 $(SONAME) $(DESTDIR)$(bindir))
else
	$(if $(SONAME), ln -f -s $(SONAME) $(DESTDIR)$(libdir)/libobe.$(SOSUFFIX))
	$(if $(SONAME), install -m 755 $(SONAME) $(DESTDIR)$(libdir))
endif
	$(if $(IMPLIBNAME), install -m 644 $(IMPLIBNAME) $(DESTDIR)$(libdir))

uninstall:
	rm -f $(DESTDIR)$(includedir)/obe.h $(DESTDIR)$(libdir)/libobe.a
	rm -f $(DESTDIR)$(bindir)/obecli$(EXE) $(DESTDIR)$(libdir)/pkgconfig/obe.pc
	$(if $(SONAME), rm -f $(DESTDIR)$(libdir)/$(SONAME) $(DESTDIR)$(libdir)/libobe.$(SOSUFFIX))

etags: TAGS

TAGS:
	etags $(SRCS)
