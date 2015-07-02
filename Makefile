#
# Tcl FogBugz API
#

PACKAGE=	fogbugz
FILES=		main.tcl 

PREFIX?=	/usr/local
LIB?=		$(PREFIX)/lib
BIN?=		$(PREFIX)/bin

TARGET?=	$(LIB)/$(PACKAGE)

UID?=		0
GID?=		0

TCLSH?=		tclsh

all:

install:	install-package install-git-hook

uninstall:	uninstall-package

install-package:
	@echo Installing $(PACKAGE) to $(TARGET)
	@install -o $(UID) -g $(GID) -m 0755 -d $(TARGET)
	@echo "  Copying $(FILES)"
	@install -o $(UID) -g $(GID) -m 0644 $(FILES) $(TARGET)
	@sed -i '' -e's/tclsh.\../$(TCLSH)/' $(TARGET)/*
	@if test -f config.tcl; then install -o $(UID) -g $(GID) -m 0644 config.tcl $(TARGET); echo "  Copying config.tcl"; fi
	@echo "  Generating pkgIndex.tcl"
	@cd $(TARGET) && echo "pkg_mkIndex -- ." | $(TCLSH)
	@echo "Installation complete"

make uninstall-package:
	rm -rf $(TARGET)

install-git-hook:
	@echo "Installing fogbugz-git-hook to $(BIN)" 
	@install -o $(UID) -g $(UID) -m 0755 tools/fogbugz-git-hook $(BIN)/ 
	@sed -i '' -e's/tclsh.\../$(TCLSH)/' $(BIN)/fogbugz-git-hook

