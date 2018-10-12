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

webthing-iotjs/default: help webthing-iotjs/build build
	@echo "# $@: $^"

webthing-iotjs/help:
	@echo "# webthing-iotjs"
	@echo "# Description: WebOfThing node for Mozilla IoT gateway using IoT.js"
	@echo "# URL: ${webthing-iotjs_url}#${webthing-iotjs_revision}"
	@echo "# Usage: Setup WiFi and flash then monitor"
	@echo "#  cd TizenRT"
	@echo "#  make -C rules/webthing-iotjs demo machine=${machine} tty=${tty}" 

${webthing-iotjs_dir}/.git:
	@rm -rf "${@D}.tmp"
	@mkdir -p "${@D}.tmp"
	git clone --recursive "${webthing-iotjs_url}" --branch "${webofthing-iotjs_revision}" "${@D}.tmp" \
 || git clone --recursive "${webthing-iotjs_url}" "${@D}.tmp"
	cd "${@D}.tmp" \
 && git reset --hard "${webthing-iotjs_revision}" \
 || git reset --hard "remotes/origin/${webthing-iotjs_revision}"
	@-mv -f "${@D}" "${@D}.bak" > /dev/null 2>&1
	@mv "${@D}.tmp" "${@D}"
	@rm -rf "${@D}.bak"
	@ls $@

${webthing-iotjs_dir}:
	${MAKE} ${@}/.git

webthing-iotjs/commit: ${webthing-iotjs_dir}/.git
	cd "${webthing-iotjs_dir}" && git describe --tag HEAD
	-cd "${<D}" && git log --pretty='%cd' HEAD --date=short "HEAD~1..HEAD" ||:
	webthing_iotjs_tag=$$(cd "${<D}" && git describe --tag HEAD) \
&& \
	webthing_iotjs_date8=$$(cd "${<D}"  && git log --pretty='%cd' HEAD --date=short "HEAD~1..HEAD") \
&& \
	${RM} -rfv \
  ${webthing-iotjs_dir}/.git \
  ${webthing-iotjs_dir}/.gitmodules \
&& \
	git add -f "${webthing-iotjs_dir}" \
&& \
	msg=$$(printf "WIP: webthing-iotjs: Import '$${webthing_iotjs_tag}' ($${webthing_iotjs_date8})\n\n\nOrigin: ${webthing-iotjs_url}#${webthing-iotjs_revision}\n") \
&& \
	git commit -am "$${msg}"

webthing-iotjs/del:
	rm -rf ${webthing-iotjs_dir} 
	-git commit -am "WIP: webthing: About to replace import (${webthing-iotjs_revision})"

webthing-iotjs/import: webthing-iotjs/del
	${MAKE} webthing-iotjs/commit

${webthing-iotjs_build_dir}: ${webthing-iotjs_dir} ${webthing-iotjs_self}
	@mkdir -p "$@"
	rsync -avx --delete "$</" "$@/"
	@-find "$@/" -iname '.git' -type d -prune -exec rm -rfv '{}' \; ||:
	@-find "$@/" -iname 'node_modules' -type d -prune -exec rm -rf '{}' \; ||:
	du -ks $@

webthing-iotjs/build: ${contents_dir}/example/index.js ${webthing-iotjs_build_dir}
	@ls $<

webthing-iotjs/demo: webthing-iotjs/help menuconfig webthing-iotjs/build build run
	@echo "#log: Then run menuconfig to configure wifi"
