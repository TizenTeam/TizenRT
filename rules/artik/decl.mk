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


platform?=artik
base_image_type?=minimal

url?=https://github.com/SamsungARTIK/artik-sdk
machine?=artik055s
machine_family?=artik05x
vendor_id?=0403
product_id?=6010

image=build/output/bin/tinyara_head.bin
deploy_image=${image}-signed
partition_map?=${CURDIR}/${configs_dir}/${machine_family}/scripts/partition_map.cfg
factory_image?=${build_dir}/output/bin/factoryimage.gz

#TODO: relocate if shared
openocd?=openocd
OPENOCD_SCRIPTS=${CURDIR}/build/tools/openocd
openocd_cfg=${CURDIR}/${configs_dir}/${machine_family}/scripts/${machine_family}.cfg
cfg=${CURDIR}/build/configs/${machine_family}/scripts/${machine_family}.cfg


signer_url?=https://developer.artik.io/downloads/artik-053s/download#
signer_archive?=${HOME}/Downloads/ARTIK053S.zip
signer?=${extra_dir}/ARTIK053/artik05x_codesigner
prep_files+=${signer}

bl1?=${CURDIR}/build/configs/${machine}/bin/bl1.bin
bl2?=${CURDIR}/build/configs/${machine}/bin/bl2.bin
sssfw?=${CURDIR}/build/configs/${machine}/bin/sssfw.bin
wlanfw?=${CURDIR}/build/configs/${machine}/bin/wlanfw.bin
os?=${CURDIR}/${deploy_image}



configure?=${os_dir}/tools/configure.sh
image_type?=minimal
image_type?=hello


machine_family?=${machine}
config_type?=${machine}/${image_type}

all+=${image} ${config} ${defconfig} ${base_defconfig}


build_dir?=build/output/bin/

base_image_type?=minimal
base_image_type?=nsh

base_defconfig?=${configs_dir}/${machine}/${base_image_type}/defconfig
defconfig?=${configs_dir}/${machine}/${image_type}/defconfig
config_type?=${machine}/${image_type}
config?=${os_dir}/.config

image?=${project}
elf_image?=${image}
deploy_image?=${image}._deploy.bin
all+=${deploy_image}

include rules/gcc-arm-embedded/decl.mk
