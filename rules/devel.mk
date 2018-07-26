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

# TODO: Override here if needed:
platform?=artik
base_image_type?=minimal

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
#TODO: upstream neededchanges and set to master or released
#iotjs_url=https://github.com/rzr/iotjs
#iotjs_branch=master
iotjs_url=https://github.com/tizenteam/iotjs
iotjs_branch=sandbox/rzr/tizenrt/build/master
#iotjs_url=file://${HOME}/mnt/iotjs

include rules/iotjs/rules.mk
#contents_rules+=devel/iotjs/contents



#{ devel
#image_type=iotivity
base_image_type=minimal

prep_files+=external/iotjs/profiles/default.profile
#prep_files+=external/iotjs/Kconfig.runtime
#prep_files+=external/iotjs.Kconfig
contents_dir?=tools/fs/contents

devel_js_minifier?=slimit
#devel_js_minifier?=yui-compressor

devel/help:
	@echo "# make demo "
	@echo "# make demo tty=/dev/ttyUSB2"

-include rules/air-lpwan-demo/rules.mk

devel/todo/xiotjs/contents: ${demo_dir} ${contents_dir}
	@echo "# log: TODO: $<"
	du -hs ${demo_dir}/ ${contents_dir}/
	mkdir -p ${contents_dir}/example/
	rsync -avx ${demo_dir}/ ${contents_dir}/example/
	rm -rf ${contents_dir}/example/.git*
	@mkdir -p ${contents_dir}/iotjs/samples
	rsync -avx external/iotjs/samples/ ${contents_dir}/iotjs/samples/
	find ${contents_dir} -iname "*~" -exec rm {} \;


-include rules/webthings/rules.mk

iotjs/local:
	-rm -f external/iotjs
	rm -rf external/iotjs/
	rsync -avx  --delete ~/mnt/iotjs/ external/iotjs/
	${make} iotjs/deps

devel/demo: ${prep_files}
	${make} -e help configure
#	grep STARTUP os/.config
#	grep IOTJS os/.config
#	grep NETCAT os/.config
	grep 'BAUD=' os/.config 
	${make} -e devel/contents deploy
	${make} -e run 
#	${make} console/screen
#	sed -e 's|115200|57600|g' -i os/.config

commit: ${demo_dir} external/iotjs/.clang-format
	ln -fs $^
	which clang-format-3.9 || sudo apt-get install clang-format-3.9
	cd $< && clang-format-3.9 -i *.js */*.js

devel/backup: ${CURDIR}/${private_dir}
	mkdir -p ${HOME}/backup/$</
	rsync -avx $</ ${HOME}/backup/${<}


#external/iotjs/profiles/%:
#	ls $@ || ${make} iotjs/import
#	ls $@

app/%: apps/examples/hello
	@echo "TODO: $@: from $^"

#TODO

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

devel/test: devel/start
	${make} devel/commit run menuconfig devel/save devel/commit
#	${make} devel/commit
	sync

#external/iotjs/Kconfig.runtime: external/iotjs/deps/jerry/targets/tizenrt-artik053/apps/jerryscript/Kconfig
#	ln -fs $< $@

-include rules/kconfig-frontends/rules.mk
#-include rules/iotivity-constrained/rules.mk


contents_rules+=devel/contents/wifi

devel/contents/wifi: ${contents_dir}/mnt/wifi/slsiwifi.conf
	cat $<

#TODO: update here with WiFi creds
devel_wifi_ssid?="private"
devel_wifi_pass?="password"

${contents_dir}/mnt/wifi/slsiwifi.conf: ${contents_dir} ${devel_self}
	@mkdir -p ${@D}
	echo 'join ${devel_wifi_ssid} ${devel_wifi_pass}' > $@



${contents_dir}:
	mkdir -p $@

devel/contents/compress:
	find ${contents_dir} -iname "*.js" \
  | while read file ; do \
  echo "#log: $${file}"; \
  ${devel_js_minifier} $${file} > $${file}.tmp && mv -v $${file}.tmp $${file} ; \
  done

devel/contents/del:
	rm -rf ${contents_dir}

devel/contents: ${contents_dir} ${contents_rules}
	@echo "#$@: $^"
	ls ${contents_dir}

#TODO
devel/contents/example: ${contents_dir}/webthing-node
	rm -rf ${contents_dir}/example
	rsync -avx ${contents_dir}/webthing-node/ ${contents_dir}/example/
	cp -av $</example/artik05x-thing.js ${contents_dir}/example/index.js

.PHONY: devel/commit

devel/webthing/demo: devel/contents/del devel/contents devel/contents/example devel/demo

demo: devel/webthing/demo
#} devel
