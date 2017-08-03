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

check: run/bg sleep/20 stop/bg
	@echo "# $@: $^"


# Helpers functions
${configs_dir}/${machine}/devel/defconfig: ${base_defconfig}
	mkdir -p ${@D}
	cp -rv ${<D}/* ${@D}
#	${MAKE} config 
#	${MAKE} -C os menuconfig

devel/start: rules/config.mk
	echo 'image_type?=devel' > ${<D}/local.mk
#	make base_image_type?=devel
#	make base_image_type?=devel menuconfig

${configs_dir}/${machine}/devel/%:
	echo 'image_type?=devel' > ${<D}/local.mk
	${make} defconfig


devel/commit: ${defconfig}
	ls $<
	git add $< 
	git add ${<D}/*.defs
	git commit -sm "WIP: Mod ${@D}"


devel/diff: ${defconfig} ${config}
	diff -u $^

devel/save: ${config}
	cp ${config} ${defconfig}

devel/del:
	git status
	rm -rf ${configs_dir}/${machine}/devel
	ls ${configs_dir}/${machine}/
	git commit -sm "WIP: Del ${defconfig}"
	echo "TODO: check local.mk"
