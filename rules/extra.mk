#! /usr/bin/make -f
# -*- makefile -*-
# ex: set tabstop=4 noexpandtab:
# -*- coding: utf-8 -*-
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in
#    the documentation and/or other materials provided with the
#    distribution.
# 3. Neither the name NuttX nor the names of its contributors may be
#    used to endorse or promote products derived from this software
#    without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
# OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
# AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
# ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
############################################################################

# board usb
tty?=$(shell ls /dev/ttyUSB* 2> /dev/null || echo /dev/TODO/setup/port | sort | head -n1)
export tty
tty_rate?=115200
export tty_rate
udev?=/etc/udev/rules.d/99-usb-${vendor_id}-${product_id}.rules
# Where to download and install tools or extra files:
extra_dir?=${HOME}/usr/local/opt/${os}/extra
# make sure user belongs to sudoers
sudo?=sudo
export sudo


extra/commit:
	git add ${configs_dir}/${machine}/${image_type} ||:
	git commit -sam "WIP: ${image_type}" ||:

extra/demo: commit cleanall menuconfig all deploy console
	${MAKE} commit

extra/run: commit done/deploy console
	${MAKE} commit

configs: build/configs/${machine}/
	ls $<
#

reset: reset/${machine}
	sync

ls: ${image}
	ls $^

configure: ${configs_dir} ${kernel}/configure
	ls $<

monitor/screen: ${tty}
	screen $< ${tty_rate}

monitor/picocom: ${tty}
	picocom -b ${tty_rate} --omap crcrlf --imap crcrlf --echo $<

monitor: monitor/screen
	sync

console: monitor


${tty}:
	ls /dev/tty*
	ls /dev/ttyUSB*
	ls $@

${udev}:
	lsusb | grep "${vendor_id}:${product_id}"
	@echo "SUBSYSTEMS==\"usb\",ATTRS{idVendor}==\"${vendor_id}\",ATTRS{idProduct}==\"${product_id}\",MODE=\"0666\" RUN+=\"/sbin/modprobe ftdi_sio RUN+=\"/bin/sh -c 'echo ${vendor_id} ${product_id} > /sys/bus/usb-serial/drivers/ftdi_sio/new_id' " \
  | ${sudo} tee $@

rule/udev: ${udev}
	cat $<
	sudo udevadm control --reload
	@echo "#TODO: su -l ${USER}"
	@echo "#TODO: replug usb : ${vendor_id}:${product_id}"
