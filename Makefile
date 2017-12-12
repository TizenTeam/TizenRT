#!/usr/bin/make -f
# -*- makefile -*-
# ex: set tabstop=4 noexpandtab:
# -*- coding: utf-8 -*-

default: rule/default
	@echo "# $@: $^"

#-include qemu.mk
#{
#machine?=artik053
#image_type?=tash
#}

#{
#TODO
url?=https://github.com/SamsungARTIK/artik-sdk
machine?=artik055s
machine_family?=artik05x
#image_type?=minimal
#image_type?=nettest
#image_type=typical
#image_type=onboard
#image_type=extra
#image_type?=tash
#image_type?=minimal
#image_type?=hello
base_config?=minimal
base_config=nettest
image_type?=devel

partition?=./build/configs/artik05x/scripts/partition_map.cfg
image_elf?=build/output/bin/tinyara
image?=build/output/bin/tinyara_head.bin
deploy_image?=${image}-signed
cfg=${CURDIR}/build/configs/${machine_family}/scripts/${machine_family}.cfg
vendor_id?=0403
product_id?=6010
#}

udev?=/etc/udev/rules.d/99-usb-${vendor_id}-${product_id}.rules
tty?=/dev/ttyUSB1
tty_rate?=115200

sdk?=${HOME}/Downloads/artik-ide-linux-x64-installer-V1.3-1020.tar.gz
signer?=${HOME}/ARTIK/SDK/A053/v1.6/source/tinyara/build/configs/artik05x/tools/codesigner/artik05x_codesigner
#signer?=${CURDIR}/build/configs/artik05x/tools/codesigner/artik05x_codesigner

machine_family?=${machine}
export machine
config_type?=${machine}/${image_type}
export config_type

config?=os/.config
MAKE+=V=1
build_dir?=build/output/bin/
openocd?=openocd
#openocd=/usr/bin/openocd -d
#openocd=openocd -d

partition?=${CURDIR}/build/configs/${machine}/tools/openocd/partition_map.cfg
bl1?=${CURDIR}/build/configs/${machine}/bin/bl1.bin
bl2?=${CURDIR}/build/configs/${machine}/bin/bl2.bin
sssfw?=${CURDIR}/build/configs/${machine}/bin/sssfw.bin
wlanfw?=${CURDIR}/build/configs/${machine}/bin/wlanfw.bin
os?=${CURDIR}/${deploy_image}

TIZENRT_BASEDIR?=${CURDIR}
OPENOCD_SCRIPTS=${CURDIR}/build/tools/openocd

cfg?=${CURDIR}/build/configs/${machine}/tools/openocd/  
#TODO
cfg=${CURDIR}/build/configs/${machine_family}/scripts/${machine_family}.cfg

gcc_package?=gcc-arm-none-eabi-4_9-2015q3

XPATH=${HOME}/mnt/${gcc_package}/bin
export XPATH
export PATH := ${XPATH}:${PATH}


rule/default: rule/all
	@echo "# $@: $^"

clean:
	rm -fv *~

cleanall: clean
	-rm -v ${deploy_image} ${image}

distclean: cleanall
	rm -f ${config}

help: Makefile
	@echo "# Available rules:"
	@grep -o "^[^ \t]*:" $<

prep: os/Make.defs
	@echo "# $@: $^"

rule/%: ${config} prep
	cd ${<D} && PATH=${PATH}:${XPATH} ${MAKE} ${@F}

${config}: os/tools/configure.sh build/configs/${config_type} #Makefile
	@echo "# Configure: ${config_type}"
	cd ${<D} && ./${<F} ${config_type}
	ls -l "$@"

config: os/tools/configure.sh build/configs/${config_type} #Makefile
	@echo "# Configure: ${config_type}"
	cd ${<D} && ./${<F} ${config_type}
	ls -l ${config}
#TODO
os/Make.defs:
	ls $@ || make config
	ls $@

menuconfig:
	ls os/.config || ${MAKE} config
	make -C os menuconfig

${image_elf}: rule/all
	@echo "# $@: $^"

${image}: ${image_elf}
	ls $@ || ${MAKE} build
	ls -l "$@"

build: rule/all
	ls -l "$@"

flash/${machine}: ${cfg} ${partition} ${bl1} ${bl2} ${sssfw} ${wlanfw} ${os}
#	cat build/configs/qemu/../${machine}/README.md
	ls ${^}
	cd ${<D} && time ${openocd} -f "${<F}" -c "\
 flash_write bl1 ${bl1};\
 flash_write bl2 ${bl2};\
 flash_write sssfw ${sssfw};\
 flash_write wlanfw ${wlanfw};\
 flash_write os ${os};\
 exit \
"

openocd/%: ${cfg}
	cd ${<D} && ${openocd} -f "${<F}" -c "${@F}; exit 0;" 2>&1

flash: flash/${machine}
	@echo "# $@: $^"

#flash: download

download/%: ${deploy_image}
	${MAKE} -C os ${@D} ${@F}

#TODO Add stamp
download: download/ALL
	@echo "# $@: $^"

# http://openocd.org/doc-release/html/index.html#toc-Reset-Configuration-1
reset: openocd/help
	@echo "press micron switch near to led and mcu of S05s"

help: openocd/help
	@echo "# $@: $^"

partition: ${partition}
	cat "$<"

ls: ${image}
	ls $^

configure: os/build/configs
	ls $<

setup/debian:
	sudo apt-get update
	sudo apt-get install git gperf libncurses5-dev flex bison
	sudo apt-get install openocd libusb-1.0
	sudo apt-get install genromfs time

console: ${tty}
	@echo "Hit reset button next to module"
	screen $< ${tty_rate}

cu?=/usr/bin/cu

test: ${tty}
	sudo sync
	sudo stty -F ${<} raw speed ${tty_rate}
	sudo stty -F ${<}
	xterm -e "cat ${<}" &
	sleep 1
	"$(shell sleep 3)cat /proc/version$(shell sleep 3)\n" | sudo tee -a ${tty}

todo/test: ${tty}
	@echo "$(shell sleep 3)cat /proc/version$(shell sleep 3)\n~." \
| ${cu} -s ${tty_rate} -l ${tty}

${cu}: /etc/debian_release
	sudo apt-get install cu

${tty}:
	ls /dev/ttyUSB*

${udev}:
	lsusb | grep "${vendor_id}:${product_id}"
	@echo "SUBSYSTEMS==\"usb\",ATTRS{idVendor}==\"${vendor_id}\",,ATTRS{idProduct}==\"${product_id}\",MODE=\"0666\" RUN+=\"/sbin/modprobe ftdi_sio RUN+=\"/bin/sh -c 'echo ${vendor_id} ${product_id} > /sys/bus/usb-serial/drivers/ftdi_sio/new_id' " | sudo tee $@

udev: ${udev}
	cat $<
#EOF

factory:
	gzip -c tinyara_head.bin-signed > factoryimage.gz
	${openocd} -f artik05x.cfg -s ../build/configs/artik05x/scripts -c ' \
    flash_write factory    ../build/configs/artik055s/bin/factoryimage.gz;      \
    exit'

sign: ${deploy_image}

firmware: ${image}
	bash -x -e ${CURDIR}/build/configs/artik05x/artik05x_user_binary.sh --topdir=${CURDIR}/os --board=${machine}

${deploy_image}: ${image} ${signer}
	${signer} -sign "${<}"
	${signer} -verify "${@}"
	ls -l "$@"

${partition}: download

#${partition}: # ${image}
#	echo build/configs/${machine}/README.md
#	cd os && bash -xe ${CURDIR}/build/configs/${machine}/${machine}_download.sh all

todo:
	cd os && sh -x -e ${CURDIR}/tools/fs/mkromfsimg.sh

configs: build/configs/${machine}/
	ls $<
#

${signer}: ${sdk}

build/configs/${machine}/devel: build/configs/${machine}/${base_config}
	cp -rf $< $@
	${MAKE} config 
	${MAKE} -C os menuconfig

all: ${firmware}
	ls $<

env:
	@echo "image_type=${image_type}"

#{ TODO

todo/os/.config: os/tools/configure.sh build/configs/${config_type} Makefile
	ls -l ${@} || { cd ${<D} && ./${<F} ${config_type}; }
	ls -l ${@}
	-cp build/configs/${config_type}/.config "$@"

commit:  build/configs/${machine}/${image_type}
	git add build/configs/${machine}/${image_type}
	git commit -sam "WIP: ${image_type}" ||:

save: 
	mkdir -p build/configs/${config_type}/ 
	cp -av ${config} build/configs/${config_type}/defconfig
	${MAKE} commit

save/%: save
	mkdir -p build/configs/${machine}/${@F}
	cp -rf build/configs/${config_type}/* build/configs/${machine}/${base_config}/
	cp ${config} build/configs/${machine}/${@F}/defconfig
	git add build/configs/${machine}/${@F} ||:
	${MAKE} commit

demo: commit cleanall menuconfig all download/ALL console
	${MAKE} console commit

diff: build/configs/${machine}/${image_type}/defconfig 
	meld $^ ${config}

devel: build/configs/${machine}/${base_config}/defconfig build/configs/${machine}/devel/defconfig 
	meld $^

devel/rm:
	rm -rf build/configs/${machine}/devel
	${MAKE} commit

TODO/minimal: build/configs/artik053/minimal/defconfig  build/configs/${machine}/minimal/defconfig 
	meld $^

TODO/055s: build/configs/${machine}/audio/defconfig ${config}
	meld $^

TODO/053: build/configs/artik053/minimal/defconfig ${config}
	meld $^

build/configs/${config_type}/.config:
	exit 1
	cp -a os/.config $@

