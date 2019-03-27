#
# CDDL HEADER START
#
# The contents of this file are subject to the terms of the
# Common Development and Distribution License, Version 1.0 only
# (the "License").  You may not use this file except in compliance
# with the License.
#
# You can obtain a copy of the license at http://smartos.org/CDDL
#
# See the License for the specific language governing permissions
# and limitations under the License.
#
# When distributing Covered Code, include this CDDL HEADER in each
# file.
#
# If applicable, add the following below this CDDL HEADER, with the
# fields enclosed by brackets "[]" replaced with your own identifying
# information: Portions Copyright [yyyy] [name of copyright owner]
#
# CDDL HEADER END
#
# Copyright 2019 Joyent, Inc.

BUILDOS=$(shell uname -s)
BUILDDIR = build
INSTALLDIRS =					\
	$(BUILDDIR)/install			\
	$(BUILDDIR)/install/javascriptlint	\

CSRCS = \
	nodepos.c		\
	pyspidermonkey.c

OBJECTS = $(CSRCS:%.c=$(BUILDDIR)/%.o)
CFLAGS += -fno-strict-aliasing -O -fPIC

SOLDFLAGS += -shared
CPPFLAGS += -DNDEBUG -D_REENTRANT					\
	-Ispidermonkey/src -Ispidermonkey/src/build			\
	-I/usr/include							\


PY_PYTHON=$(shell python -c "import sys; print(sys.executable)")
PY_PREFIX=$(shell $(PY_PYTHON) -c "import sys; print(sys.prefix)")
PY_VERSION=$(shell $(PY_PYTHON) -c "import sys; print('.'.join(map(str, sys.version_info[:2])))")
ifeq ($(BUILDOS),Darwin)
	PY_ARCH=$(shell $(PY_PYTHON) -c 'import sys; print (sys.maxint > 2**32 and "x86_64" or "i386")')
	SOLDFLAGS += $(PY_PREFIX)/Python
	CC=gcc -arch $(PY_ARCH)
else
	PY_BIT=$(shell $(PY_PYTHON) -c 'import sys; print (sys.maxint > 2**32 and "64" or "32")')
	CFLAGS += -m$(PY_BIT)
endif

CPPFLAGS += -I$(PY_PREFIX)/include/python$(PY_VERSION)
SOFILE = $(BUILDDIR)/pyspidermonkey.so

all: $(SOFILE)

$(BUILDDIR) $(INSTALLDIRS):
	mkdir -p $@

$(OBJECTS): spidermonkey/src/build/libjs.a spidermonkey/src/build/js_operating_system.h

$(SOFILE): $(OBJECTS)
	$(CC) $(CFLAGS) $(SOLDFLAGS) $(LDFLAGS) $(OBJECTS) -Lspidermonkey/src/build -ljs -o $@

$(BUILDDIR)/%.o: javascriptlint/pyspidermonkey/%.c | $(BUILDDIR)
	$(CC) -o $@ -c $(CFLAGS) $(CPPFLAGS) $<

spidermonkey/src/build/libjs.a:
	(cd spidermonkey/src && CC="$(CC)" CFLAGS="$(CFLAGS)" $(MAKE))

spidermonkey/src/build/js_operating_system.h:
	echo "#define XP_UNIX" > $@

check test:
	@echo What could go wrong?

clean:
	-rm -rf $(BUILDDIR) $(INSTALLDIRS)
	-(cd spidermonkey/src && $(MAKE) clean)

install: $(SOFILE) javascriptlint/jsl javascriptlint/jsl | $(INSTALLDIRS)
	cp $(SOFILE) build/install
	cp javascriptlint/*.py build/install/javascriptlint
	sed -e "1s:#\!/usr/bin/env python:#\!$(PY_PYTHON):" javascriptlint/jsl >build/install/jsl
	chmod +x build/install/jsl
	sed -e "1s:#\!/usr/bin/env python:#\!$(PY_PYTHON):" javascriptlint/jsl.py >build/install/javascriptlint/jsl.py
	chmod +x build/install/javascriptlint/jsl.py
	sed -e "1s:#\!/usr/bin/env python:#\!$(PY_PYTHON):" javascriptlint/jsparse.py >build/install/javascriptlint/jsparse.py
	sed -e "1s:#\!/usr/bin/env python:#\!$(PY_PYTHON):" javascriptlint/lint.py >build/install/javascriptlint/lint.py

.PHONY: install
