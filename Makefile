#! /usr/bin/make -f
XPATH=${HOME}/mnt/gcc-arm-none-eabi-4_9-2015q3/bin

export XPATH
machine?=lm3s6965evb
export machine
config?=qemu/tash_16m
export config

qemu?=qemu-system-arm
MAKE+=V=1
export PATH := ${XPATH}:${PATH}

default: rule/all

distclean:
	rm -f os/.config

help: Makefile
	@echo "# Available rules:"
	@grep -o "^[^ \t]*:" $<

rule/%: os/.config
	cd ${<D} && PATH=${PATH}:${XPATH} ${MAKE} ${@F}

os/.config: os/tools/configure.sh build/configs/${config}
	ls -l ${@} || { cd ${<D} && ./${<F} ${config}; }
	ls -l ${@}
	-cp build/configs/${config}/.config "$@"

config: os/.config
	make -C ${<D} menuconfig

run: build/output/bin/tinyara
	ls -l ${<D}
	${qemu} -M ${machine} -kernel $< -nographic

run/bg: build/output/bin/tinyara
	ls -l ${<D}
	${qemu} -M ${machine} -kernel $< -nographic &
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
