#
# Tcl FogBugz API
#

PACKAGE=	fogbugz
FILES=		common.tcl 

PREFIX?=	/usr/local
TARGET?=	$(PREFIX)/lib/$(PACKAGE)

UID?=		0
GID?=		0

TCLSH?=		tclsh8.5

install:
	@echo Installing $(PACKAGE) to $(TARGET)
	@install -o $(UID) -g $(GID) -m 0755 -d $(TARGET)
	@echo "  Copying $(FILES)"
	@install -o $(UID) -g $(GID) -m 0644 $(FILES) $(TARGET)
	@if test -f config.tcl; then install -o $(UID) -g $(GID) -m 0644 config.tcl $(TARGET); echo "  Copying config.tcl"; fi
	@echo "  Generating pkgIndex.tcl"
	@cd $(TARGET) && echo "pkg_mkIndex -- ." | $(TCLSH)
	@echo "Installation complete"
