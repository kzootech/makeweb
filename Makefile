# file: Makefile
# auth: Andrew Alm <https://kzoo.tech>
# desc: Makefile for makeweb static website generator, see README.md for further
#       information.
# 
# Copyright (c) 2020, Andrew Alm <https://kzoo.tech>
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
# REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY 
# AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, 
# INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM 
# LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
# OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR 
# PERFORMANCE OF THIS SOFTWARE.
#

.PHONY: all clean htdocs html preview publish 
.PHONY: on-all on-clean on-htdocs on-html on-preview on-publish

# default commands (things not typically found /bin), assume they are in $PATH
FIND  := find 
PERL  := PERL5LIB=$(TOPDIR)/perl5lib/ perl
RSYNC != whereis openrsync
.if $(RSYNC)
RSYNC := openrsync --rsync-path=openrsync
.else
RSYNC := rsync
.endif

# enumerate src/ directory  
TOPDIR  != pwd
SRC     != $(FIND) src/ -type f -name "*.md" ! -name index.md | sed "s/src\///g"
HTFILES != $(FIND) src/ -type f ! -name "*.md" | sed "s/src\///g"

# default target
all: htdocs html

# these targets are triggered before the main target, do nothing by default
on-all:
on-clean:
on-htdocs:
on-html:
on-preview:
on-publish:

.include "Makefile.site"

# clean htdocs 
clean: on-clean
	rm -rf htdocs/*

# copy static files to htdocs/
htdocs: on-htdocs $(HTDOCS:%=htdocs/%)

.for file in $(HTFILES)
htdocs/$(file): src/$(file)
	mkdir -p htdocs/`echo $(file) | sed -e "s/[^\/]*$$//"`
	cp -p src/$(file) htdocs/$(file)
.endfor

# generate html in from src/ to htdocs/
html: on-html $(SRC:%.md=htdocs/%/index.html) htdocs/index.html htdocs/style.css

.for page in $(SRC:%.md=%)
htdocs/$(page)/index.html: src/$(page).md template.pl
	mkdir -p htdocs/$(page)
	cd src/; $(PERL) ../template.pl $(page).md > ../htdocs/$(page)/index.html
.endfor

htdocs/index.html: src/index.md template.pl
	cd src/; $(PERL) ../template.pl index.md > ../htdocs/index.html

# publish/preview using rsync; requires user-interaction
.poison empty (PUBLISH-DIR)
preview: on-preview
	$(RSYNC) -r --del htdocs/ $(PREVIEW-DIR)/

.poison empty (PREVIEW-DIR)
publish: on-publish
	$(RSYNC) -r --del htdocs/ $(PUBLISH-DIR)/

