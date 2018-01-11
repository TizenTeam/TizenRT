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
rules_dir?=${topdir}/rules
platform?=artik
base_image_type?=minimal

platform?=artik
machine_family?=artik05x
machine?=${platform}055s
vendor_id?=0403
product_id?=6010
toolchain?=gcc-arm-embedded

image=${build_dir}/output/bin/tinyara_head.bin
deploy_image=${image}

configure?=${os_dir}/tools/configure.sh
image_type?=minimal
config_type?=${machine}/${image_type}
build_dir?=${top_dir}/build/output/bin/

base_image_type?=minimal

base_defconfig?=${configs_dir}/${machine}/${base_image_type}/defconfig
defconfig?=${configs_dir}/${machine}/${image_type}/defconfig
config_type?=${machine}/${image_type}
config?=${os_dir}/.config

all+=${image} ${config} ${defconfig} ${base_defconfig}
all+=${deploy_image}

setup_debian_rules+=artik/setup/debian

include ${rules_dir}/${toolchain}/decl.mk
