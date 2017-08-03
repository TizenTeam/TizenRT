#! /usr/bin/make -f
XPATH=${HOME}/mnt/gcc-arm-none-eabi-4_9-2015q3/bin

export XPATH
machine?=lm3s6965evb
export machine
config?=qemu/tash_16m
export config

qemu?=qemu-system-arm


default: rule/all

rule/%: os/.config
	PATH=${XPATH}:${PATH} make -C ${<D} ${@F}

os/.config: os/tools/configure.sh build/configs/${config}
	ls -l ${@} || { cd ${<D} && ./${<F} ${config}; }
	ls -l ${@}

config: os/.config
	make -C ${<D} menuconfig

run: build/output/bin/tinyara
	ls -l ${<D}
	${qemu} -M ${machine} -kernel $< -nographic

build/output/bin/tinyara: rule/all

stop:
	killall ${qemu}

iotivity: distclean build/configs/artik053/iotivity
	make config=artik053/iotivity

distclean:
	rm -f os/.config

build/configs/${config}/.config: os/.config
	cp -a $< $@

save: build/configs/${config}/.config 
