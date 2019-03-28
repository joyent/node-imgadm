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
#
#
# imgadm Makefile
#


TOP		= $(PWD)
JSLINT		= $(TOP)/tools/javascriptlint/build/install/jsl
JSSTYLE		= $(TOP)/tools/jsstyle
JSSTYLE_OPTS	= -o indent=4,strict-indent=1,doxygen,unparenthesized-return=0,continuation-at-front=1,leading-right-paren-ok=1

SUBDIRS		= tools/javascriptlint

export PATH := /usr/node/bin:$(PATH)

all	: TARGET = all
clean	: TARGET = clean
install	: TARGET = install
check	: TARGET = check
test	: TARGET = test
test	: export PATH := $(TOP)/sbin:/usr/node/bin:$(PATH)

#
# Targets
#

all: $(SUBDIRS)

.PHONY: $(SUBDIRS)
$(SUBDIRS):
	cd $@ && $(MAKE) TOP=$(TOP) $(TARGET)

.PHONY: install
install: $(SUBDIRS)
	npm install

.PHONY: clean
clean: $(SUBDIRS)
	-npm uninstall

.PHONY: test
test: $(SUBDIRS)
	./test/runtests

.PHONY: check
check: $(SUBDIRS)
	@printf "\n==> Running JavaScriptLint...\n"
	$(JSLINT) --nologo --conf tools/jsl.node.conf lib/*.js
	@printf "\n==> Running jsstyle...\n"
	@# jsstyle doesn't echo as it goes so we add an echo to each line below
	@(for file in lib/*.js; do \
		echo $(PWD)/$$file; \
		$(JSSTYLE) $(JSSTYLE_OPTS) $$file || exit 1; \
	done)
	@printf "\nJS style ok!\n"

.PHONY: update_modules
update_modules:
	./tools/update-node-modules.sh

INSTALLIMAGE=/var/tmp/img-install-image
.PHONY: dev-install-image
dev-install-image:
	rm -rf $(INSTALLIMAGE)
	mkdir -p $(INSTALLIMAGE)
	cp package.json $(INSTALLIMAGE)/
	mkdir -p $(INSTALLIMAGE)/etc
	cp etc/imgadm.completion $(INSTALLIMAGE)/etc/
	mkdir -p $(INSTALLIMAGE)/sbin
	cp sbin/* $(INSTALLIMAGE)/sbin/
	cp -PR lib $(INSTALLIMAGE)/lib
	cp -PR node_modules $(INSTALLIMAGE)/node_modules
	cp -PR test $(INSTALLIMAGE)/test
	mkdir -p $(INSTALLIMAGE)/tools
	cp -PR tools/coal-create-docker-vm.sh $(INSTALLIMAGE)/tools/
	mkdir -p $(INSTALLIMAGE)/man
	@echo SKIPPING "node ../../tools/ronnjs/bin/ronn.js man/imgadm.1m.md > $(INSTALLIMAGE)/man/imgadm.1m"
