#! /usr/bin/make -f

#{
#machine?=qemu
#qemu_machine?=lm3s6965evb
#image_type?=tash_16m
#qemu?=qemu-system-arm
#}

#{
#machine?=artik053
#image_type?=tash
#}

#{
url?=https://github.com/SamsungARTIK/artik-sdk
machine?=artik055s
machine_family?=artik05x
# bin  extra  minimal  nettest  onboard  README.md  scripts  typical
#image_type?=nettest
#image_type=devel
image_type=extra
#image_type=typical
#image_type=onboard
partition?=./build/configs/artik05x/scripts/partition_map.cfg
image?=build/output/bin/tinyara_head.bin
deploy_image?=${image}-signed
cfg=${CURDIR}/build/configs/${machine_family}/scripts/${machine_family}.cfg
vendor_id?=0403
product_id?=6010
#}

udev?=/etc/udev/rules.d/99-usb-${vendor_id}-${product_id}.rules
tty?=/dev/ttyUSB1

sdk?=${HOME}/Downloads/artik-ide-linux-x64-installer-V1.3-1020.tar.gz
signer?=${HOME}/ARTIK/SDK/A053/v1.6/source/tinyara/build/configs/artik05x/tools/codesigner/artik05x_codesigner
#signer?=${CURDIR}/build/configs/artik05x/tools/codesigner/artik05x_codesigner


#image_type?=nettest
#image_type?=tash
#image_type?=minimal
image_type?=hello

machine_family?=${machine}
export machine
config?=${machine}/${image_type}
export config

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


default: rule/all

distclean:
	rm -f os/.config

help: Makefile
	@echo "# Available rules:"
	@grep -o "^[^ \t]*:" $<

prep: os/Make.defs
	@echo "# $@: $^"

rule/%: os/.config prep
	cd ${<D} && PATH=${PATH}:${XPATH} ${MAKE} ${@F}


os/.config: os/tools/configure.sh build/configs/${config} Makefile
	 cd ${<D} && ./${<F} ${config}

todo/os/.config: os/tools/configure.sh build/configs/${config} Makefile
	ls -l ${@} || { cd ${<D} && ./${<F} ${config}; }
	ls -l ${@}
	-cp build/configs/${config}/.config "$@"


os/Make.defs:
	ls $@ || make config
	ls $@

config: os/tools/configure.sh build/configs/${config} Makefile
	@echo "# Configure: ${config}"
	cd ${<D} && ./${<F} ${config}
	ls -l os/.config

menuconfig:
	ls os/.config || ${MAKE} config
	make -C os menuconfig

run: build/output/bin/tinyara
	ls -l ${<D}
	${qemu} -M ${qemu_machine} -kernel $< -nographic

run/bg: build/output/bin/tinyara
	ls -l ${<D}
	${qemu} -M ${qemu_machine} -kernel $< -nographic &
	echo $? > pid.tmp

sleep/%:
	sleep ${@F}

build/output/bin/tinyara: rule/all

stop:
	killall ${qemu}

stop/bg: pid.tmp
	kill $$(cat ${<}) && rm $<


build/configs/${config}/.config: os/.config
	cp -a $< $@

save: build/configs/${config}/.config 

check: run/bg sleep/20 stop/bg


image: rule/all

${image}:
	ls $@ || ${MAKE} image
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

#flash: download

download: ${deploy_image}
	${MAKE} -C os download ALL


# http://openocd.org/doc-release/html/index.html#toc-Reset-Configuration-1
reset: openocd/help
	@echo "press siwtcg near to leds"

help: openocd/help

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
	screen $< 115200

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

build/configs/${machine}/devel: build/configs/${machine}/extra 
	cp -rf $< $@
	${MAKE} config 
	${MALE} -C os menuconfig
