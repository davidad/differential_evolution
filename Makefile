all: de
	@echo -e "To benchmark, try\n\n > time luajit de.lua\n\nor\n\n > time ./de\n"

de: de.c
	gcc -O3 de.c -o de

PLAT := $(shell uname -sm | sed -e 's/ /-/g')
UNAMEA := $(shell uname -a)
UNAME_NOHOST := $(shell uname -mprsv)
GCCV := $(shell gcc -v 2>&1)
LUAJITV := $(shell luajit -v)
HASH := $(shell echo -e "$(UNAMEA)\n\n$(GCCV)\n\n$(LUAJITV)" | openssl sha1 | sed -e 's/^.*= *//' -e 'y/abcdef/ABCDEF/' | xxd -r -p | base64 | colrm 8 | tr '+/' '-_')
HOSTID := host$(HASH)
WD := results/$(PLAT)/$(HOSTID)

bench: $(WD)/README.txt $(WD)/versions.csv

$(WD)/README.txt: $(WD) luajit
	@echo -e "creating $(WD)/README.txt..."
	@echo -e "  (feel free to add your own information about your hardware or software setup!)"
	@echo -e "Host:\n$(UNAME_NOHOST)\n\nGCC Version:\n$(GCCV)\n\nLuaJIT Version:\n$(LUAJITV)\n\n#Add other information here" > $(WD)/README.txt

luajit:
ifeq ($(shell which luajit),)
	@echo -e "LuaJIT doesn't appear to be installed on your system. Run\n\n > make luajit_build\n\nto attempt building it locally."
	@false
else
	@echo -e "locating luajit... " $(shell which luajit)
	ln -s $(shell which luajit) luajit
endif

$(WD): luajit
	mkdir -p $(WD)

luajit-2.0:
	git clone http://luajit.org/git/luajit-2.0.git

luajit-2.0/bin/luajit: luajit-2.0
	make -C luajit-2.0

luajit_build: luajit-2.0/bin/luajit
	ln -s luajit-2.0/bin/luajit luajit
	@echo -e "Okay, now try\n\n > make bench\n\nagain..."
