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
devel_self?=rules/devel.mk
configs_dir?=build/configs

defconfig?=${configs_dir}/${machine}/devel/defconfig
# TODO: Override here if needed:
platform?=artik
machine?=${platform}055s
base_image_type?=iotjs

# Default:
os?=tinyara
platform?=qemu
base_image_type?=tc_64k
base_defconfig?=${configs_dir}/${machine}/${base_image_type}/defconfig
defconfigs?=$(wildcard build/configs/*/${base_image_type}/defconfig)

# Where to download and install tools or extra files:
extra_dir?=${HOME}/usr/local/opt/${os}/extra

# make sure user belongs to sudoers
sudo?=sudo
export sudo

# Overload external dep to be pulled
#TODO: upstream neededchanges and set to master or released
#iotjs_url=https://github.com/rzr/iotjs
#iotjs_branch=master
#iotjs_url=https://github.com/tizenteam/iotjs
#iotjs_branch=sandbox/rzr/tizenrt/master
#iotjs_url=file://${HOME}/mnt/iotjs

-include rules/iotjs/rules.mk
#contents_rules+=devel/iotjs/contents
#contents_rules+=devel/contents/example


#{ devel
#image_type=iotivity
#base_image_type=minimal
base_image_type=iotjs

#prep_files+=${private_dir}/config.js
#prep_files+=external/iotjs/profiles/default.profile
#prep_files+=external/iotjs/Kconfig.runtime
#prep_files+=external/iotjs.Kconfig
contents_dir?=tools/fs/contents
prep_files+=${contents_dir}

devel_js_minifier?=slimit
#devel_js_minifier?=yui-compressor
