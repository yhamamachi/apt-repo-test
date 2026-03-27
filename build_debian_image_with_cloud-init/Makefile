SHELL := /bin/bash
ARCH ?= arm64
SUITE ?= trixie
MIRROR ?= http://deb.debian.org/debian

NAME ?= sparrowhawk
DATE := $(shell date +%Y%m%d)
OUTDIR := out
ROOTFS := $(OUTDIR)/rootfs
IMG := $(OUTDIR)/$(NAME)-$(SUITE)-$(ARCH)-$(DATE).img
XZ := $(IMG).xz
REPO := $(OUTDIR)/repo.json

SIZE_GIB ?= 4
BOOT_MIB ?= 512

.PHONY: all clean rootfs repo

all: $(REPO)

rootfs.done:
	rm -f rootfs.done
	-mkdir $(OUTDIR)
	sudo scripts/01_build_rootfs.sh "$(ARCH)" "$(SUITE)" "$(MIRROR)" "$(ROOTFS)" && touch rootfs.done

$(IMG).xz: rootfs.done
	sudo scripts/02_make_disk_image.sh "$(ROOTFS)" "$(IMG)" "$(SIZE_GIB)" "$(BOOT_MIB)" 
	sudo scripts/03_pack_and_hash.sh "$(IMG)"

$(REPO): $(IMG).xz
	python3 scripts/04_update_repo_json.py "$(XZ)" "$(REPO)" "http://rcar.kenichi3.mydns.jp/sh-image/$(notdir $(XZ))" "http://rcar.kenichi3.mydns.jp/sh-image/sh-mascot.png"

clean:
	sudo rm -rf "$(OUTDIR)" rootfs.done

install:
	sudo cp $(REPO) $(IMG).xz /var/www/html/sh-image
