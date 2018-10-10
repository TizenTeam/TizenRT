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
top_dir?=.
rules_dir?=${top_dir}/rules

include ${rules_dir}/${toolchain}/rules.mk

qemu/run: ${deploy_image}
	@ls -l ${<D}
	@echo "# log: To stop type killall ${qemu}"
	@echo "# log: Type reset if no prompt after $@"
	sleep 10
	${qemu} -M ${qemu_machine} -kernel $< -nographic

qemu/run/bg:
	{ ${MAKE} qemu/run || reset } &
	echo $? > pid.tmp

qemu/monitor: qemu/run
	@echo "# log: $@: $^"

qemu/deploy:
	@echo "# log: uneeded for ${platform}"

qemu/sleep/%:
	sleep ${@F}

qemu/stop:
	@echo "# log: TODO: use pid amd reset"
	killall ${qemu}
	-reset

qemu/stop/bg: pid.tmp
	kill $$(cat ${<}) && rm $<

qemu/check: qemu/run/bg qemu/sleep/20 qemu/stop/bg
	@echo "# $@: $^"

qemu/setup/debian:
	${sudo} apt-get install -y qemu-system-arm
