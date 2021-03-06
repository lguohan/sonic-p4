thisdir := $(shell pwd)
installdir := $(thisdir)/install
builddir := $(thisdir)/build
NPROCS:=1
OS:=$(shell uname -s)
ifeq ($(OS),Linux)
	NPROCS:=$(shell grep -c ^processor /proc/cpuinfo)
endif

BLD_OPTIONS := -DSWITCHAPI_ENABLE -DSWITCHSAI_ENABLE
P4FLAGS :=

BMV2_PERF_FLAGS = -O2
# BMV2_PERF_FLAGS = -O0 -g

all: driver

p4-bmv2.ts: SUBMODULE = $(thisdir)/p4-bmv2
p4-bmv2.ts:
	cd $(SUBMODULE); ./autogen.sh; cd -; \
	mkdir -p $(builddir)/p4-bmv2; \
	cd $(builddir)/p4-bmv2; $(SUBMODULE)/configure --prefix=$(installdir) --with-pdfixed 'CXXFLAGS=$(BMV2_PERF_FLAGS)'; \
	$(MAKE) -j$(NPROCS); $(MAKE) install; cd -;
	@touch $@

p4c-bmv2.ts: SUBMODULE = $(thisdir)/p4c-bmv2
p4c-bmv2.ts:
	mkdir -p $(builddir)/p4c-bmv2; \
	cd $(SUBMODULE); \
        python setup.py build -b $(builddir)/p4c-bmv2 install --prefix $(installdir) --single-version-externally-managed --record $(builddir)/install_files.txt; \
	cd -;
	@touch $@

setup-target.ts: p4-bmv2.ts p4c-bmv2.ts
	cd switch; ./autogen.sh; cd -; \
	mkdir -p $(builddir)/switch; cd $(builddir)/switch; \
	$(thisdir)//switch/configure --prefix=$(installdir) --with-bmv2 --enable-thrift --with-switchsai 'CXXFLAGS=-O0 -g' 'CFLAGS=-O0 -g'; cd -;
	@touch $@

flags.ts: FORCE
	@echo '$(BLD_OPTIONS)' | cmp -s - $@ || echo '$(BLD_OPTIONS)' > $@

p4-flags.ts: FORCE
	@echo '$(P4FLAGS)' | cmp -s - $@ || echo '$(P4FLAGS)' > $@

driver-clean.ts: flags.ts setup-target.ts
	$(MAKE) -C $(builddir)/switch/switchapi clean
	$(MAKE) -C $(builddir)/switch/switchsai clean
	touch $(thisdir)/switch/bmv2/bmv2_init.c
	touch $(thisdir)/switch/bmv2/main.c
	@touch $@

p4-clean.ts: p4-flags.ts setup-target.ts
	$(MAKE) -C $(builddir)/switch clean
	@touch $@

driver-compile: setup-target.ts driver-clean.ts p4-clean.ts
	$(MAKE) P4PPFLAGS='$(P4FLAGS)' CPPFLAGS="$(BLD_OPTIONS)" -j$(NPROCS) -C $(builddir)/switch
	$(MAKE) P4PPFLAGS='$(P4FLAGS)' CPPFLAGS="$(BLD_OPTIONS)" -C $(builddir)/switch install

driver: driver-compile
	cp $(installdir)/bin/bmswitchp4_drivers $(installdir)/bin/driver-bmv2
	rm -f $(installdir)/lib/libsai.so
	cp $(installdir)/lib/libbmswitchp4.so.0.0.0 $(installdir)/lib/libsai.so

clean:
	rm -f p4-bmv2.ts p4c-bmv2.ts setup-target.ts flags.ts driver-clean.ts
	rm -f p4-flags.ts p4-clean.ts

full-clean: clean
	rm -rf build install

install: driver
	echo "Installing in " $(DESTDIR)
	cp -R install/* $(DESTDIR)

.PHONY: clean full-clean FORCE driver-compile
