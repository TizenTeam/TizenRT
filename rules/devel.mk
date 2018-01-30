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
image_type=iotivity
base_image_type=nettest

prep_files+=${CURDIR}/extra/private/config.js
prep_files+=external/iotjs/profiles/default.profile
prep_files+=external/iotjs/Kconfig.runtime
contents_dir?=tools/fs/contents

js_minifier?=slimit
#js_minifier?=yui-compressor


${contents_dir}:
	mkdir -p $@

contents: extra/ ${contents_dir}
	@echo "# log: TODO: $<"
	du -hs $^
	rsync -avx $^
	@mkdir -p ${contents_dir}/iotjs/samples
	rsync -avx external/iotjs/samples/ ${contents_dir}/iotjs/samples/
	find ${contents_dir} -iname "*~" -exec rm {} \;
	find ${contents_dir} -iname "*.js" \
  | while read file ; do \
  echo "#log: $${file}"; \
  ${js_minifier} $${file} > $${file}.tmp && mv -v $${file}.tmp $${file} ; \
  done

demo: ${prep_files}
	${make} -e help configure
#	grep STARTUP os/.config
#	grep IOTJS os/.config
#	grep NETCAT os/.config
	grep 'BAUD=' os/.config 
	${make} -e contents deploy
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
	mkdir -p ${@D}
	ls $@ || rsync -avx ${HOME}/backup/${@D}/ ${@D}/ || echo "TODO"
	ls $@

external/iotjs/profiles/%:
	ls $@ || ${make} iotjs/import
	ls $@

app/%: apps/examples/hello
	@echo "TODO: $@: from $^"

#TODO

tizen_iotivity_example_url?=https://github.com/tizenteam/iotivity-example
tizen_iotivity_example_branch?=sandbox/rzr/tizen/1.2-rel

local/iotivity-example-tizen:
	git clone ${tizen_iotivity_example_url} -b ${tizen_iotivity_example_branch} $@
	cd $@ && ./tizen.mk tpk

tizen: local/iotivity-example-tizen
	ls $^


iotivity_example_url?=https://github.com/tizenteam/iotivity-example
iotivity_example_branch?=sandbox/rzr/tizen/rt/1.2-rel
apps/examples/iotivity_example: 
	mkdir -p ${@D}
	git clone --recursive -b ${iotivity_example_branch} ${iotivity_example_url} $@
	ls $@

apps/examples/iotivity_example/%: apps/examples/iotivity_example
	ls $@

prep_files+=apps/examples/iotivity_example/Kconfig

local/apps/examples/iotivity_example: ${HOME}/mnt/iotivity-example/
	-rm $@
	mkdir -p ${@}
	rsync -avx $</ $@/

TODO/apps/examples/iotivity-example: ${HOME}/mnt/iotivity-example
	mkdir -p ${@D}
	ln -fs $< $@

#TODO
ocf_my_light_url?=https://github.com/webispy/ocf_mylight
#ocf_my_light_branch?=oic_1.1 # 1.2-rel
ocf_my_light_branch?=master

apps/examples/ocf_mylight:
	git clone --recursive ${ocf_my_light_url} -b ${ocf_my_light_branch} $@

ocf: apps/examples/ocf_mylight ./external/iotivity/iotivity_1.3-rel/resource/csdk/stack/include
	ln -fsv ${CURDIR}/external/iotivity/iotivity_1.3-rel/out/tizenrt/armv7-r/release/include/c_common/iotivity_config.h ./external/iotivity/iotivity_1.3-rel/resource/csdk/stack/include
	ln -fsv ${CURDIR}/./external/iotivity/iotivity_1.3-rel/build_common/tizenrt/compatibility/*.h ./external/iotivity/iotivity_1.3-rel/resource/csdk/stack/include/
	ln -fsv ${CURDIR}/./external/iotivity/iotivity_1.3-rel/resource/csdk/include/*.h ./external/iotivity/iotivity_1.3-rel/resource/csdk/stack/include/
	grep '^CONFIG_EXAMPLES_OCFMYLIGHT' ${config} || ${make} menuconfig

ioty: ${HOME}/mnt/iotivity-example/ apps/examples/iotivity_example/
	rsync -avx $^
	ls $</Kconfig*
	grep '^CONFIG_EXAMPLES_IOTIVITY_EXAMPLE' ${config} || ${make} menuconfig
	${make}

local_mk?=rules/local.tmp.mk

devel/start: rules/config.mk clean
	@echo 'image_type=devel' > ${local_mk}
#	@echo "TODO"
#	@echo 'base_image_type=devel' > ${local_mk}
#	@echo 'image_type?=devel' > ${local_mk}
#	make base_image_type?=devel
#	make base_image_type?=devel menuconfig


${configs_dir}/${machine}/devel/%:
	echo 'image_type?=devel' > ${local_mk}
	git add ${local_mk}
	git commit -sm "WIP: devel: (${machine})" ${local_mk}
	${make} defconfig

devel/commit: ${defconfig}
	ls $<
	git add $< 
	git add ${<D}/*.defs
	git status \
  && git commit -sm "WIP: devel: (${machine})" ${<D} \
  || echo "TODO $@"

devel/diff: ${defconfig} ${config}
	diff -u $^

devel/del:
	git status
	rm -rf ${configs_dir}/${machine}/devel
	ls ${configs_dir}/${machine}/
	git commit -sm "WIP: devel: Del (${machine})" ${configs_dir}/${machine}/
	echo "TODO: check ${local_mk}"

devel/demo: devel/start
	${make} devel/commit run menuconfig devel/save devel/commit
#	${make} devel/commit
	sync

artik_sdk_url?=https://github.com/SamsungARTIK/artik-sdk.git

external/artik-sdk:
	git clone --recursive ${artik_sdk_url} $@

artik/import: external/artik-sdk

iotjs/local:
	-rm -f external/iotjs
	rm -rf external/iotjs/
	rsync -avx  --delete ~/mnt/iotjs/ external/iotjs/
	${make} iotjs/deps

.PHONY: devel/commit

#} devel
