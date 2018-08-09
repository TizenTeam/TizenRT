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
#TODO
webthing_project ?= webthing-iotjs
webthing_rules_dir ?= ${CURDIR}/rules/webthing
iotjs_main ?= ${webthing_rules_dir}/index.js

devel/help:
	@echo "# make demo "
	@echo "# make demo tty=/dev/ttyUSB2"

devel/todo/iotjs/contents: ${demo_dir} ${contents_dir}
	@echo "# log: TODO: $<"
	du -hs ${demo_dir}/ ${contents_dir}/
	mkdir -p ${contents_dir}/example/
	rsync -avx ${demo_dir}/ ${contents_dir}/example/
	rm -rf ${contents_dir}/example/.git*
	@mkdir -p ${contents_dir}/iotjs/samples
	rsync -avx external/iotjs/samples/ ${contents_dir}/iotjs/samples/
	find ${contents_dir} -iname "*~" -exec rm {} \;

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
	${make} -e devel/contents/example
	${make} -e deploy
	${make} -e run 
#	${make} console/screen
#	sed -e 's|115200|57600|g' -i os/.config

devel/iotjs/commit: ${demo_dir} external/iotjs/.clang-format
	ln -fs $^
	which clang-format-3.9 || sudo apt-get install clang-format-3.9
	cd $< && clang-format-3.9 -i *.js */*.js

devel/backup: ${CURDIR}/${private_dir}
	mkdir -p ${HOME}/backup/$</
	rsync -avx $</ ${HOME}/backup/${<}

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
	git commit -sm "WIP: devel: Update defconfig (${machine})" ${local_mk}
	${make} defconfig

devel/commit: ${defconfig}
	ls $<
	git add $< 
	git add ${<D}/*.defs
	git status \
  && git commit -sm "WIP: devel: Update defconfig (${machine})" ${<D} \
  || echo "TODO $@"
	git status \
  && git commit -sm "WIP: devel Update machine (${machine})" "${configs_dir}/${machine}" \
  || echo "TODO $@"

devel/diff: ${defconfig} ${config}
	diff -u $^

devel/del:
	git status
	rm -rf ${configs_dir}/${machine}/devel
	ls ${configs_dir}/${machine}/
	git status \
|| git commit -sm "WIP: devel: Del (${machine})" "${configs_dir}/${machine}/"
	echo "TODO: check ${local_mk}"

devel/save: os/.config
	cp -av $< ${defconfig}

devel/update: devel/save ${defconfig}
	cp -av ${defconfig} ${base_defconfig}

devel/test: devel/start
	${make} devel/commit
	${make} menuconfig run devel/save devel/commit
#	${make} devel/commit
	sync


#external/iotjs/Kconfig.runtime: external/iotjs/deps/jerry/targets/tizenrt-artik053/apps/jerryscript/Kconfig
#	ln -fs $< $@

-include rules/kconfig-frontends/rules.mk
#-include rules/iotivity-constrained/rules.mk

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

devel/contents: devel/contents/del ${contents_dir} ${contents_rules}
	@echo "#$@: $^"
	ls ${contents_dir}

#devel/demo: 

#	@echo "Ready"
## demo


devel/contents/example: webthing/contents ${contents_dir}/example/index.js
#	rm -rf ${contents_dir}/example
#	mkdir -p ${contents_dir}/iotjs-modules/${webthing_project}
#	rsync -avx ${contents_dir}/${webthing_project}/ ${contents_dir}/iotjs-modules/${webthing_project}/
#	find ${contents_dir}/ -type d -iname '.git' -exec rm -rf {} \;
#	find ${contents_dir}/ -type d -iname 'node_modules' -exec rm -rf {} \;
#	${MAKE} 
	du -ks ${contents_dir}

${contents_dir}/example/index.js: ${iotjs_main} ${contents_dir}
	install -d ${@D}
	install $< $@

devel/machine/%:
	${MAKE} -e machine=${@F} help
	${MAKE} -e machine=${@F} distclean
	${MAKE} -e machine=${@F} devel/del
	${MAKE} -e machine=${@F} menuconfig
	${MAKE} -e machine=${@F} all
	${MAKE} -e machine=${@F} devel/save devel/update devel/commit

devel/machines: ${defconfigs}
	ls $^
	for path in $^ ; do \
 machine=$$(echo "$${path}" \
 | sed -e "s|build/configs/\(.*\)/${base_image_type}/defconfig|\1|g") ;\
 ${MAKE} devel/machine/$${machine} ; \
done

devel/machines/del:
	rm -rf build/configs/*/devel
#TODO
demo: clean devel/demo

.PHONY: devel/commit

#} devel
