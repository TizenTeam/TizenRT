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

#IOTJS_ROOT_DIR ?= $(EXTDIR)/iotjs

#TODO
date8?=$(shell date +%Y-%m-%d -u)
git?=git

iotjs_dir?=external/iotjs
iotjs_url?=https://github.com/Samsung/iotjs
iotjs_branch?=master
iotjs_tag?=release_1.0
iotjs_profile?=tizenrt
iotjs_kconfig?=${iotjs_dir}/config/tizenrt/Kconfig.runtime

iotjs_prep_files+=${iotjs_dir}/deps/jerry/CMakeLists.txt
iotjs_prep_files+=${iotjs_kconfig}

prep_files+=${iotjs_prep_files}



${iotjs_dir}/deps/%:  ${iotjs_dir}
	-@ls ${iotjs_dir}/.git ${iotjs_dir}/.gitmodules
	@ls $@ || cd ${iotjs_dir} && git submodule update --init --recursive 

${iotjs_dir}:
	ls $@ || ${MAKE} ${iotjs_dir}/.git

${iotjs_dir}/.git:
	rm -rf "${@D}"
	git clone -b "${iotjs_branch}" --recursive "${iotjs_url}" "${@D}"
	@ls $@

${iotjs_dir}/%: ${iotjs_dir}
	@ls $@

${iotjs_profile_file}: ${iotjs_dir}
	@ls $@

iotjs/prep: ${iotjs_dir}  ${iotjs_prep_files}
	ls $<

iotjs/del:
	rm -rf ${iotjs_dir} 
	-git commit -am "WIP: iotjs: About to replace import (${iotjs_branch})"

iotjs/import: iotjs/del 
	${make} iotjs/prep
	${make} iotjs/commit

iotjs/download: ${iotjs_dir}/.git
	ls $<

iotjs/release:
	${make} iotjs_branch="${iotjs_tag}" iotjs/del iotjs/download iotjs/commit

iotjs/commit: ${iotjs_dir}/.git
	cd "${iotjs_dir}" && git describe --tag ${iotjs_branch}
	-cd "${<D}" && git log --pretty='%cd' ${iotjs_branch} --date=short "HEAD~1..HEAD" ||:
	iotjs_tag=$$(cd "${<D}" && git describe --tag "${iotjs_branch}") \
&& \
	iotjs_date8=$$(cd "${<D}"  && git log --pretty='%cd' "${iotjs_branch}" --date=short "HEAD~1..HEAD") \
&& \
	${RM} -rfv \
  ${iotjs_dir}/.git \
  ${iotjs_dir}/.gitmodules \
  ${iotjs_dir}/deps/*/.git \
  ${iotjs_dir}/deps/*/*.gitmodules \
&& \
	git add -f "${iotjs_dir}" \
&& \
	git commit -sam "\
WIP: iotjs: Import '$${iotjs_tag}' ($${iotjs_date8})\n\
\n\
Origin: ${iotjs_url}#${iotjs_branch}\n\
"

iotjs/setup/debian: /etc/debian_version
	sudo apt-get install -y cmake python

