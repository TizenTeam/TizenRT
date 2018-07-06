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


help: ${README} help
	cat $<
	@echo "# os=${os}"
	@echo "# config_type=${config_type}"
	@echo "# "
	@echo "# build_dir=${build_dir}"
	@echo "# apps_dir=${apps_dir}"
	@echo "# config=${config}"
	@echo "# defconfig=${defconfig}"
	@echo "# base_defconfig=${base_defconfig}"
	@echo "# deploy_image=${deploy_image}"
	@echo "# image=${image}"
	@echo "# image_type=${image_type}"
	@echo "# machine=${machine}"
	@echo "# prep_files=${prep_files}"

longhelp: ${self}
	@echo "# Available rules:"
	@grep -o "^[^ \t]*:" rules/*.mk

undefined/%:
	@echo "error: $@ (unexpected)"


#all: rule/all
#	sync

clean:
	-rm -fv ${config}
	-rm -f *~

cleanall: clean
	-rm -v ${deploy_image} ${image}
	-rm -rf tmp

distclean: cleanall
	rm -f ${config}

rule/%: ${config}
	cd ${<D} && PATH=${PATH}:${XPATH} ${MAKE} ${@F}

rule/make: ${config}
	cd ${<D} && PATH=${PATH}:${XPATH} ${MAKE}

apps_dir: ${apps_dir}
	ls $<

#${config}: ${configure} ${defconfig}
#	ls -l $^
#	cd ${<D} && ./${<F} ${config_type}
#	ls -l ${config}

rule/configure: ${config}
	ls -l ${config}

${os_dir}/Make.defs:
	ls $@ || ${make} rule/configure

rule/prep: ${prep_files}
	ls $<

rule/all: ${all} rule/make
	ls ${all}

rule/default: rule/prep all
	@echo "# $@: $^"

${image}: rule/make
	ls -l "$@"

defconfig: ${defconfig}
	ls $^

menuconfig: ${os_dir} ${config} 
	${MAKE} -C $< $@


${platform}/%: rules/${platform}/rules.mk
	@echo "# $@ can be overidden in $^"

${tmp_dir}/rule/done/deploy: ${platform}/deploy
	mkdir -p ${@D}
	touch $@

done/deploy: ${tmp_dir}/rule/done/deploy
	@ls $<

deploy: ${tmp_dir}/rule/done/deploy
	@echo "# $@: $^"

run: done/deploy ${platform}/run
	sync


.PHONY: rule/configure rule/make
