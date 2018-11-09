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
all+=${prep_files}
done_dir?=${tmp_dir}/done
# TODO
SHELL=/bin/bash

base/default: base/build
	@echo "# $@: $^"

%/%:
	@echo "# $@ can be overidden elsewhere"

${done_dir}/rule/%: rule/%
	@mkdir -p "${@D}"
	touch "$@"

once/rule/%:
	@ls "${@:once/%=${done_dir}/%}" > /dev/null 2>&1 \
 || ${MAKE} "${@:once/%=${done_dir}/%}"
	@ls "${@:once/%=${done_dir}/%}"

os/%: ${config}
	PATH="${PATH}:${XPATH}" ${MAKE} -C ${<D} ${@F}

os/make: ${prep_files} ${CC} ${config}
	${CC} --version
	PATH="${PATH}:${XPATH}" ${MAKE} -C ${<D}
	@ls -l "$<"

${deploy_image}: ${image}
	@ls -la "$@"

${image}: ${prep_files} ${CC} ${config} ${contents_dir}
	PATH="${PATH}:${XPATH}" ${MAKE} -C ${os_dir}
	@ls -la "${@D}"
	@ls -la "$@"

images: ${deploy_image} ${image}
	@ls -l $<

deploy/platform: ${platform}/deploy
	@echo "# log: $@: $^"

rule/deploy: deploy/platform
	@echo "# log: $@: $^"

${done_dir}/rule/deploy: ${all}
	${MAKE} rule/deploy
	@mkdir -p "${@D}"
	touch "$@"

deploy: ${done_dir}/rule/deploy 
	@ls "$<"

base/%: %
	@echo "# $@: $^"

help:
	@echo "## Usage:"
	@echo "# make help"
	@echo "# make menuconfig # To reconfigure settings"
	@echo "# make build # To build image"
	@echo "# make deploy # To upload to target (if relevant)"
	@echo "# make monitor # console to target (if relevant)"
	@echo "# make demo # To rebuild all and run on target"

readme: ${README}
	cat "$<"

print:
	@echo "## Configuration"
	@echo "# os=${os}"
	@echo "# config_type=${config_type}"
	@echo "# "
	@echo "# PATH=${PATH}"
	@echo "# SHELL=${SHELL}"
	@echo "# all=${all}"
	@echo "# apps_dir=${apps_dir}"
	@echo "# base_defconfig=${base_defconfig}"
	@echo "# build_dir=${build_dir}"
	@echo "# config=${config}"
	@echo "# contents_dir=${contents_dir}"
	@echo "# defconfig=${defconfig}"
	@echo "# defconfigs=${defconfigs}"
	@echo "# deploy_image=${deploy_image}"
	@echo "# image=${image}"
	@echo "# image_type=${image_type}"
	@echo "# machine=${machine}"
	@echo "# os_dir=${os_dir}"
	@echo "# platform=${platform}"
	@echo "# prep_files=${prep_files}"
	@echo "# rules_dir=${rules_dir}"
	@echo "# tmp_dir=${tmp_dir}"
	@echo "# top_dir=${top_dir}"
	@echo "# tty=${tty}"

longhelp: ${self} print
	@echo "# Available rules:"
	grep -o "^[^ \t]*:" ${rules_dir}/*/*.mk

undefined/%:
	@echo "error: $@ (unexpected)"

all rule/all: ${all}
	ls -l $^

${platform}/%: ${rules_dir}/${platform}/rules.mk
	@echo "# $@ can be overidden in $^"

${project_name}/%: ${rules_dir}/${project_name}/rules.mk
	@echo "# $@ can be overidden in $^"

build/project: ${project_name}/build
	@echo "# log: $@: $^"

build: build/project prep os/make
	ls ${all}
	@echo "# log: $@: $^"

clean:
	-rm -fv ${config}
	-rm -f *~

cleanall: clean
	-rm -v ${deploy_image} ${image}
	-rm -rf tmp

distclean: cleanall
	[ ! -d .git ] || git clean -f -X

apps_dir: ${apps_dir}
	@ls $<

os/configure: ${config}
	@ls -l ${config}

configure: ${prep_files} ${configs_dir} ${kernel}/configure
	@ls $<

prep: ${prep_files}
	@ls $<

rule/default: prep all
	@echo "# log: $@: $^"

${os_dir}/tools/%:
	@ls ${os_dir} || ${MAKE} ${os_dir}
	${MAKE} -C ${os_dir} tools/${@F} CC=gcc

${os_dir}/Make.defs:
	@ls $@ > /dev/null 2>&1 || ${MAKE} os/configure

${defconfig}: ${base_defconfig}
	@ls $@ > /dev/null 2>&1 \
 && echo "# TODO: update manually $@ from $<" || echo "# Create $@ from $<"
	@mkdir -p ${@D}
	@ls $@ > /dev/null 2>&1 || cp -rav ${<D}/* ${@D}
	@ls $@

defconfig: ${defconfig}
	@ls $^

defconfig/save: ${config}
	@cp -av ${config} ${defconfig}
	@ls -l ${defconfig}

menuconfig: ${os_dir} ${config}
	[[ $$- == *i* ]] && echo "# log: Skip $@ (terminal is not interactive)" || ${MAKE} -C $< $@
	@ls -l ${config}

reconfigure:
	rm ${config}
	${MAKE} ${config}

run: deploy ${platform}/run
	@echo "# log: $@: $^"

%/demo: prep menuconfig all deploy run
	@echo "# log: $@: $^"

demo: help print ${project}/demo
	@echo "# log: $@: $^"

contents/del:
	@rm -rf ${contents_dir}
	-git checkout ${contents_dir}/.gitignore

.PHONY: os/configure os/make
