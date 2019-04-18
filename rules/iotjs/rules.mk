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

iotjs/default: iotjs/help iotjs/build build
	@echo "# $@: $^"

iotjs/help:
	@echo "IoT.js upstream can be imported to TizenRT"
	@echo "URL: ${iotjs_url}#${iotjs_revision}"

${iotjs_dir}:
	@ls $@ > /dev/null 2>&1 \
 || ${MAKE} ${iotjs_dir}/.git

${iotjs_dir}/.git:
	@rm -rf "${@D}.tmp"
	@mkdir -p "${@D}.tmp"
	git clone --recursive -b ${iotjs_revision} "${iotjs_url}" "${@D}.tmp" \
 || git clone --recursive "${iotjs_url}" "${@D}.tmp"
	cd "${@D}.tmp" \
 && git reset --hard "${iotjs_revision}" \
 || git reset --hard "remotes/origin/${iotjs_revision}"
	@-mv -f "${@D}" "${@D}.bak" > /dev/null 2>&1
	@mv "${@D}.tmp" "${@D}"
	@rm -rf "${@D}.bak"
	ls $@

${iotjs_dir}/%: ${iotjs_dir}
	@ls $@ > /dev/null 2>&1 || ${MAKE} iotjs/download
	@ls $@

${iotjs_dir}/deps/%: ${iotjs_dir}
	@ls $@ > /dev/null 2>&1 \
 || cd ${iotjs_dir} && git submodule update --init --recursive 

${iotjs_profile_file}: ${iotjs_dir}
	@ls $@

iotjs/prep: ${iotjs_dir} ${iotjs_prep_files}
	@ls $<

iotjs/del:
	rm -rf ${iotjs_dir} 
	-git commit -am "WIP: iotjs: About to replace import (${iotjs_revision})"

iotjs/import: iotjs/del
	${MAKE} iotjs/prep
	${MAKE} iotjs/commit

iotjs/download: ${iotjs_dir}/.git
	@ls $<

iotjs/release:
	${MAKE} iotjs_revision="${iotjs_tag}" iotjs/del iotjs/download iotjs/commit

iotjs/commit: ${iotjs_dir}/.git
	cd "${<D}" && git describe --tag HEAD 
	-cd "${<D}" && git log --pretty='%cd' HEAD --date=short "HEAD~1..HEAD" ||:
	iotjs_tag=$$(cd "${<D}" && git describe --tag HEAD) \
&& \
	iotjs_date8=$$(cd "${<D}"  && git log --pretty='%cd' "${iotjs_revision}" --date=short "HEAD~1..HEAD") \
&& \
	${RM} -rfv \
  ${iotjs_dir}/.git \
  ${iotjs_dir}/.gitmodules \
  ${iotjs_dir}/deps/*/.git \
  ${iotjs_dir}/deps/*/*.gitmodules \
&& \
	git add -f "${iotjs_dir}" \
&& \
	msg=$$(printf "WIP: iotjs: Import '$${iotjs_tag}' ($${iotjs_date8})\n\n\nOrigin: ${iotjs_url}#${iotjs_revision}\n") \
&& \
	git commit -sam "$${msg}"

iotjs/reset: ${iotjs_dir}
	rm -rf $<
	git checkout HEAD $<

iotjs/setup/debian: /etc/debian_version
	${sudo} apt-get install -y cmake python

${contents_dir}/example/%.js: ${rules_dir}/${project_name}/%.js
	install -d ${@D}
	install $^ ${@D}

iotjs/build: ${contents_dir}/example/index.js
	@ls $<

iotjs/demo: iotjs/help
	${MAKE} -e help configure
	${MAKE} -e deploy
	${MAKE} -e ${@D}/deploy
	${MAKE} -e run

${contents_dir}/example/%.js: ${iotjs_example_dir}/%.js
	install -d ${@D}
	install $^ ${@D}
