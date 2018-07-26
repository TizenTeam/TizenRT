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

#{openocd
openocd/%: ${openocd_cfg}
	cd ${<D} && ${openocd} -f "${<F}" -c "${@F}; exit 0;" 2>&1
#}openocd

artik/help: ${configs_dir}/${machine}/README.md rules/${platform}/decl.mk rules/${platform}/rules.mk
	-cat $<
	@echo "# ${make} openocd/help"
	@echo "# deploy_image=${deploy_image}"
	@echo "# cfg=${openocd_cfg}"
	@echo "# tty=${tty}"
	${signer} -h

${deploy_image}: ${image} ${signer}
	${signer} -sign "${<}"
	${signer} -verify "${@}"
	ls -l "$@"

artik/image: ${deploy_image}
	ls -l $^

artik/deploy/openocd/${machine}: ${openocd_cfg} ${partition_map} ${bl1} ${bl2} ${sssfw} ${wlanfw} ${deploy_image}
	@echo "TODO: use download instead"
	exit 1
	ls ${^}
	cd ${<D} && time ${openocd} -f "${<F}" -c "\
 flash_write bl1 ${bl1};\
 flash_write bl2 ${bl2};\
 flash_write sssfw ${sssfw};\
 flash_write wlanfw ${wlanfw};\
 flash_write os ${CURDIR}/${deploy_image};\
 exit \
"

# http://openocd.org/doc-release/html/index.html#toc-Reset-Configuration-1
reset/%: openocd/help
	@echo "press micron switch near to led and mcu of S05s"

${signer_archive}: 
	@echo "# Please download from:"
	@echo "# ${signer_url}#${@F}"
	ls $@

${signer}: ${signer_archive}
	@echo "unpack $< to $@"
	mkdir -p ${@D} && cd ${@D} && ls $@ || unzip ${<}
	chmod a+rx $@
	@ls $@

artik/signer: ${signer}
	ls $<
	-$< -h


artik/sign: ${deploy_image}
	ls -l "$<"

${sdk}:
	@echo "TODO: download it to: $@"
	ls $@


artik/partition: ${partition_map}
	cat "$<"

${partition_map}:
	ls -l "$@" || ${make} artik/download
	ls -l "$@"

#TODO remove?
#${partition}: # ${image}
#	echo build/configs/${machine}/README.md
#	cd os && bash -xe ${CURDIR}/build/configs/${machine}/${machine}_download.sh all


${factory_image}: ${deploy_image}
	ls $^
	cd ${@D} && gzip -c tinyara_head.bin-signed > ${@F}
	ls -l $@

artik/factory: ${openocd_cfg} ${factory_image} ${partition_map}
	cd ${<D} && time ${openocd} -f "${<F}" -c "\
 help ; \
 flash_erase_part ota ;\
 flash_write factory ${CURDIR}/${factory_image}; \
 exit\
"

#TODO
artik/firmware: ${CURDIR}/build/configs/artik05x/artik05x_user_binary.sh ${image}
	bash -x -e $< --topdir=${CURDIR}/os --board=${machine}


#{generic
#TODO
#build/output/bin/tinyara: rule/all
#	@echo "# $@: $^"


artik/deploy: artik/deploy/${machine}
	@echo "# $@: $^"


artik/deploy/%: ${deploy_image} os
	@echo "TODO: only download ${@F}"
	ls -l $<
	${MAKE} -C os download ALL


#flash: download
artik/download: ${deploy_image}
	${MAKE} -C os download ALL

#artik/deploy/${machine}: deploy/${machine}
#	sync

artik/deploy/help: openocd/help
	@echo "# $@: $^"


#TODO:

artik/todo:
	cd os && sh -x -e ${CURDIR}/tools/fs/mkromfsimg.sh

artik/run: console
	echo "TODO deploy once"

.PHONY: artik/download

artik/prep: ${prep_files}
	ls $<

artik/setup:
	sudo apt-get install -y genromfs openocd

#} generic

include rules/gcc-arm-embedded/rules.mk
