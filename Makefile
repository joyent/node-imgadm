#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

#
# Copyright 2019 Joyent, Inc.
#

NAME = imgadm

SHELL = /bin/bash

#
# Tools
#
TAPE :=			./node_modules/.bin/tape

#
# If we need to use buildimage, make sure we declare that before including
# Makefile.defs since that conditionally sets macros based on
# ENGBLD_USE_BUILDIMAGE.
#
ENGBLD_USE_BUILDIMAGE   = false

#
# Makefile.defs defines variables used as part of the build process.
# Ensure we have the eng submodule before attempting to include it.
#
ENGBLD_REQUIRE          := $(shell git submodule update --init deps/eng)
include ./deps/eng/tools/mk/Makefile.defs
TOP ?= $(error Unable to access eng.git submodule Makefiles.)

#
# Configuration used by Makefile.defs and Makefile.targ to generate
# "check" and "docs" targets.
#
BASH_FILES =
DOC_FILES =		index.md boilerplateapi.md
JSON_FILES =		package.json
JS_FILES :=		$(shell find lib test -name '*.js')
JSL_FILES_NODE =	$(JS_FILES)
JSSTYLE_FILES =		$(JS_FILES)

JSL_CONF_NODE =		deps/eng/tools/jsl.node.conf
JSSTYLE_FLAGS =		-f tools/jsstyle.conf

INSTALL	=		install
PREFIX =		/opt/img

#
# Historically, Node packages that make use of binary add-ons must ship their
# own Node built with the same compiler, compiler options, and Node version that
# the add-on was built with.  On SmartOS systems, we use prebuilt Node images
# via Makefile.node_prebuilt.defs.  On other systems, we build our own Node
# binary as part of the build process.  Other options are possible -- it depends
# on the need of your repository.
#
NODE_PREBUILT_VERSION =	v6.17.0
ifeq ($(shell uname -s),SunOS)
	NODE_PREBUILT_TAG = zone64
	# Use the sdcnode build for minimal-64-lts@18.4.0
	NODE_PREBUILT_IMAGE = c2c31b00-1d60-11e9-9a77-ff9f06554b0f
	include ./deps/eng/tools/mk/Makefile.node_prebuilt.defs
else
	NPM=npm
	NODE=node
	NPM_EXEC=$(shell which npm)
	NODE_EXEC=$(shell which node)
endif

#
# If a project needs to include Triton/Manta agents as part of its image,
# include Makefile.agent_prebuilt.defs and define an AGENTS macro to specify
# which agents are required.
#
include ./deps/eng/tools/mk/Makefile.agent_prebuilt.defs


#
# If a project includes some components written in the Go language, the Go
# toolchain will need to be available on the build machine.  At present, the
# Makefile library only handles obtaining a toolchain for SmartOS systems.
#
ifeq ($(shell uname -s),SunOS)
	GO_PREBUILT_VERSION =	1.9.2
	GO_TARGETS =		$(STAMP_GO_TOOLCHAIN)
	GO_TEST_TARGETS =	test_go
	include ./deps/eng/tools/mk/Makefile.go_prebuilt.defs
endif

ifeq ($(shell uname -s),SunOS)
	CTF_TARGETS =		helloctf
	CTF_TEST_TARGETS =	test_ctf
	include ./tools/mk/Makefile.ctf.defs
endif

#
# Makefile.node_modules.defs provides a common target for installing modules
# with NPM from a dependency specification in a "package.json" file.  By
# including this Makefile, we can depend on $(STAMP_NODE_MODULES) to drive "npm
# install" correctly.
#
include ./deps/eng/tools/mk/Makefile.node_modules.defs

#
# Configuration used by Makefile.manpages.defs to generate manual pages.
# See that Makefile for details.  MAN_SECTION must be eagerly defined (with
# ":="), but the Makefile can be used multiple times to build manual pages for
# different sections.
#
MAN_INROOT =		docs/man
MAN_OUTROOT =		man
CLEAN_FILES +=		$(MAN_OUTROOT)

MAN_SECTION :=		1
include ./deps/eng/tools/mk/Makefile.manpages.defs
MAN_SECTION :=		3bapi
include ./deps/eng/tools/mk/Makefile.manpages.defs

#
# Set for buildimage to have pkgin update and full-upgrade before installing
# BUILDIMAGE_PKGSRC packages.
#
# BUILDIMAGE_DO_PKGSRC_UPGRADE=true

#
# Repo-specific targets
#
.PHONY: all
all: $(SMF_MANIFESTS) $(STAMP_NODE_MODULES) $(GO_TARGETS) | $(REPO_DEPS)

#
# This example Makefile defines a special target for building manual pages.  You
# may want to make these dependencies part of "all" instead.
#
.PHONY: manpages
manpages: $(MAN_OUTPUTS)

.PHONY: install
install:
	me=`whoami`; \
	cat manifest.in | \
	    sed -e '/^#/ d' -e '/^$$/ d' -e 's,@PREFIX@,$(PREFIX),g' | \
	    while read type path mode user group; do \
	        if [[ $$me == root ]]; then \
	                args="-o $$user -g $$group"; \
	        else \
	                args=; \
	        fi; \
	        case $$type in \
	        d)      echo $(INSTALL) $$args -p -d "$(DESTDIR)$$path" ;; \
	        f)      echo $(INSTALL) $$args -p -T "$${path#$(PREFIX)/}" \
	                    "$(DESTDIR)$$path" ;; \
	        s)      link="$${path%%=*}"; \
	                path="$${path#*=}"; \
	                echo mkdir -p `dirname $(DESTDIR)$$link`; \
	                echo ln -sf $$path $(DESTDIR)$$link \
	                ;; \
	        *)      echo "Invalid line:" \
	                    '$$type $$path $$mode $$user $$group' 1>&2; \
	                exit 1; \
	                ;; \
	        esac; \
	    done | bash -ve

.PHONY: test
test: $(STAMP_NODE_MODULES) $(GO_TEST_TARGETS) $(TEST_CTF_TARGETS)
	$(NODE) $(TAPE) test/*.test.js

#
# Target definitions.  This is where we include the target Makefiles for
# the "defs" Makefiles we included above.
#

include ./deps/eng/tools/mk/Makefile.deps

ifeq ($(shell uname -s),SunOS)
	include ./deps/eng/tools/mk/Makefile.node_prebuilt.targ
	include ./deps/eng/tools/mk/Makefile.go_prebuilt.targ
	include ./deps/eng/tools/mk/Makefile.agent_prebuilt.targ
endif

MAN_SECTION :=		1
include ./deps/eng/tools/mk/Makefile.manpages.targ
MAN_SECTION :=		3bapi
include ./deps/eng/tools/mk/Makefile.manpages.targ

include ./deps/eng/tools/mk/Makefile.smf.targ
include ./deps/eng/tools/mk/Makefile.node_modules.targ
include ./deps/eng/tools/mk/Makefile.ctf.targ
include ./deps/eng/tools/mk/Makefile.targ
