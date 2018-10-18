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

mastodon-lite/default: help mastodon-lite/build build
	@echo "# $@: $^"

mastodon-lite/help:
	@echo "# mastodon-lite"
	@echo "# Description: WebOfThing node for Mozilla IoT gateway using IoT.js"
	@echo "# URL: ${mastodon-lite_url}#${mastodon-lite_revision}"
	@echo "# Usage: Setup WiFi and flash then monitor"
	@echo "#  cd TizenRT"
	@echo "#  make -C rules/mastodon-lite demo machine=${machine} tty=${tty}" 

${mastodon-lite_dir}/.git:
	@rm -rf "${@D}.tmp"
	@mkdir -p "${@D}.tmp"
	git clone --recursive "${mastodon-lite_url}" --branch "${webofthing-iotjs_revision}" "${@D}.tmp" \
 || git clone --recursive "${mastodon-lite_url}" "${@D}.tmp"
	cd "${@D}.tmp" \
 && git reset --hard "${mastodon-lite_revision}" \
 || git reset --hard "remotes/origin/${mastodon-lite_revision}"
	@-mv -f "${@D}" "${@D}.bak" > /dev/null 2>&1
	@mv "${@D}.tmp" "${@D}"
	@rm -rf "${@D}.bak"
	@ls $@

${mastodon-lite_dir}:
	${MAKE} ${@}/.git

mastodon-lite/commit: ${mastodon-lite_dir}/.git
	cd "${mastodon-lite_dir}" && git describe --tag HEAD
	-cd "${<D}" && git log --pretty='%cd' HEAD --date=short "HEAD~1..HEAD" ||:
	mastodon_lite_tag=$$(cd "${<D}" && git describe --tag HEAD) \
&& \
	mastodon_lite_date8=$$(cd "${<D}"  && git log --pretty='%cd' HEAD --date=short "HEAD~1..HEAD") \
&& \
	${RM} -rfv \
  ${mastodon-lite_dir}/.git \
  ${mastodon-lite_dir}/.gitmodules \
&& \
	git add -f "${mastodon-lite_dir}" \
&& \
	msg=$$(printf "WIP: mastodon-lite: Import '$${mastodon_lite_tag}' ($${mastodon_lite_date8})\n\n\nOrigin: ${mastodon-lite_url}#${mastodon-lite_revision}\n") \
&& \
	git commit -am "$${msg}"

mastodon-lite/del:
	rm -rf ${mastodon-lite_dir} 
	-git commit -am "WIP: webthing: About to replace import (${mastodon-lite_revision})"

mastodon-lite/import: mastodon-lite/del
	${MAKE} mastodon-lite/commit

${mastodon-lite_build_dir}: ${mastodon-lite_dir} ${mastodon-lite_self}
	@mkdir -p "$@"
	rsync -avx --delete "$</" "$@/"
	@-find "$@/" -iname '.git' -type d -prune -exec rm -rfv '{}' \; ||:
	@-find "$@/" -iname 'node_modules' -type d -prune -exec rm -rf '{}' \; ||:
	du -ks $@

${contents_dir}/%.json: ${rules_dir}/mastodon-lite/%.json
	install -d ${@D}
	install $^ ${@D}

mastodon-lite/build: ${contents_dir}/example/index.js ${mastodon-lite_build_dir}
	@ls $<

mastodon-lite/demo: mastodon-lite/help menuconfig mastodon-lite/build build run
	@echo "#log: Then run menuconfig to configure wifi"
