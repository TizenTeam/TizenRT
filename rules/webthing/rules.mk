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

webthing_self?=rules/webthing/rules.mk
#TODO: Pin latest version
#webthing_revision?=webthing-iotjs-0.7.0
webthing_revision?=master
webthing_project?=webthing-iotjs
webthing_url?=https://github.com/rzr/${webthing_project}
webthing_dir?=external/${webthing_project}

contents_dir?=tools/fs/contents
contents_rules+=webthing/contents


${webthing_dir}/.git:
	@rm -rf "${@D}"
	@mkdir -p "${@D}"
	git clone --recursive "${webthing_url}" "${@D}"
	cd "${@D}" && git reset --hard "${webthing_revision}"
	@ls $@

${webthing_dir}:
	ls $@ || ${MAKE} ${webthing_dir}/.git

webthing/commit: ${webthing_dir}/.git
	cd "${webthing_dir}" && git describe --tag HEAD
	-cd "${<D}" && git log --pretty='%cd' HEAD --date=short "HEAD~1..HEAD" ||:
	webthing_tag=$$(cd "${<D}" && git describe --tag HEAD) \
&& \
	webthing_date8=$$(cd "${<D}"  && git log --pretty='%cd' HEAD --date=short "HEAD~1..HEAD") \
&& \
	${RM} -rfv \
  ${webthing_dir}/.git \
  ${webthing_dir}/.gitmodules \
&& \
	git add -f "${webthing_dir}" \
&& \
	msg=$$(printf "WIP: webthing: Import '$${webthing_tag}' ($${webthing_date8})\n\n\nOrigin: ${webthing_url}#${webthing_revision}\n") \
&& \
	git commit -sam "$${msg}"


webthing/prep: ${webthing_dir}  ${webthing_prep_files}
	ls $<

webthing/del:
	rm -rf ${webthing_dir} 
	-git commit -am "WIP: webthing: About to replace import (${webthing_revision})"

webthing/import: webthing/del
	${make} webthing/prep
	${make} webthing/commit

${contents_dir}/iotjs-modules/${webthing_project}: ${webthing_dir} ${webthing_self}
	mkdir -p "$@"
	rsync -avx --delete "$</" "$@/"
	@-find "$@/" -iname '.git' -type d -exec rm -rfv '{}' \; ||:
	@-find "$@/" -iname 'node_modules' -type d -exec rm -rf '{}' \; ||:
	du -ks $@

webthing/contents: ${contents_dir}/iotjs-modules/${webthing_project}
	du -ms $<

webthing/home: ${HOME}/mnt/${webthing_project}
	mkdir -p "${contents_dir}/${webthing_project}" 
	rsync -avx "${HOME}/mnt/${webthing_project}/" "${contents_dir}/${webthing_project}/" 
	@-find "${contents_dir}/${webthing_project}/" -iname '.git' -exec rm -rf '{}' \; ||:
	@-find "${contents_dir}/${webthing_project}/" -iname 'node_modules' -exec rm -rf '{}' \; ||:
