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


#default: rule/default
#	@echo "# $@: $^"

# TODO: Override here if needed:
platform?=artik
base_image_type?=nettest

# Default:
os?=tinyara
platform?=qemu
base_image_type?=tc_64k

# Where to download and install tools or extra files:
extra_dir?=${HOME}/usr/local/opt/${os}/extra

# make sure user belongs to sudoers
sudo?=sudo
export sudo

# Overload external dep to be pulled
iotjs_url=https://github.com/tizenteam/iotjs
iotjs_branch=master
#iotjs_branch=sandbox/rzr/devel/demo/master
#iotjs_url=file://${HOME}/mnt/iotjs
#iotjs_branch=sandbox/rzr/devel/tizenrt/master


include rules/iotjs/rules.mk


#{ devel
example: extra/ tools/fs/contents
	@echo "# log: TODO: $<"
	du -hs $^
	rsync -avx $^

image_type=devel
base_image_type=devel

demo: ${CURDIR}/extra/private/config.js
	${make} -e help configure
	grep STARTUP os/.config
	grep IOTJS os/.config
	grep NETCAT os/.config
	grep 'BAUD=' os/.config 
	${make} -e example deploy
	${make} -e run 
#	${make} console/screen  # baudrate=57600
#	sed -e 's|115200|57600|g' -i os/.config

commit: external/iotjs/.clang-format extra
	ln -fs $^
	which clang-format-3.9 || sudo apt-get install clang-format-3.9
	cd extra && clang-format-3.9 -i *.js */*.js

backup: ${CURDIR}/extra/private/
	mkdir -p ${HOME}/backup/$</
	rsync -avx $</ ${HOME}/backup/${<}

${CURDIR}/extra/private/%:
	ls $@ || rsync -avx ${HOME}/backup/${@D} ${@D} || echo "TODO"
	ls $@

#} devel
