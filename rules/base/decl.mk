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
MAKE+=V=1
self?=${rules_dir}/build.mk
export make
os_dir?=${CURDIR}
build_dir?=${os_dir}
tmp_dir?=${top_dir}/tmp/${project_name}/${machine}
export tmp_dir
apps_dir?=${top_dir}/apps
machine?=qemu
export machine
base_image_type?=minimal
config_dir?=${build_dir}/configs
base_defconfig?=${configs_dir}/${machine}/${base_image_type}/defconfig
image_type?=${base_image_type}
config_type?=${machine}/${image_type}
defconfig?=${configs_dir}/${config_type}/defconfig
defconfigs?=$(wildcard build/configs/*/${base_image_type}/defconfig)
configure?=${os_dir}/tools/configure.sh
config?=${os_dir}/.config
image?=${build_dir}/output/bin/${project}
contents_dir?=${top_dir}/tools/fs/contents
contents_rules?=
deploy_image?=${image}
all+=${deploy_image}
project_name?=devel
image_type?=${project_name}
prep_files+=${os_dir}/Make.defs
README?=$(wildcard ${top_dir}/README*)
