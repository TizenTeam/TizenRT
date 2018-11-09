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

air-lpwan-demo/default: air-lpwan-demo/build build
	@echo "# $@: $^"

air-lpwan-demo/help:
	@echo "# air-lpwan-demo"
	@echo "# Description: WebOfThing node for Mozilla IoT gateway using IoT.js"
	@echo "# URL: ${air-lpwan-demo_url}#${air-lpwan-demo_revision}"
	@echo "# Usage: Setup WiFi and flash then monitor"
	@echo "#  cd TizenRT"
	@echo "#  make -C rules/air-lpwan-demo demo machine=${machine} tty=${tty}" 

${air-lpwan-demo_dir}/.git:
	@rm -rf "${@D}.tmp"
	@mkdir -p "${@D}.tmp"
	git clone --recursive "${air-lpwan-demo_url}" --branch "${air-lpwan-demo_revision}" "${@D}.tmp" \
 || 	git clone --recursive "${air-lpwan-demo_url}" "${@D}.tmp"
	cd "${@D}.tmp" \
 && git reset --hard "${air-lpwan-demo_revision}" \
 || git reset --hard "remotes/origin/${air-lpwan-demo_revision}"
	@-mv -f "${@D}" "${@D}.bak" > /dev/null 2>&1
	@mv "${@D}.tmp" "${@D}"
	@rm -rf "${@D}.bak"
	@ls $@

${air-lpwan-demo_dir}:
	ls $@ >/dev/null 2>&1 || ${MAKE} ${air-lpwan-demo_dir}/.git

air-lpwan-demo/commit: ${air-lpwan-demo_dir}/.git
	cd "${air-lpwan-demo_dir}" && git describe --tag HEAD
	-cd "${<D}" && git log --pretty='%cd' HEAD --date=short "HEAD~1..HEAD" ||:
	air_lpwan_demo_tag=$$(cd "${<D}" && git describe --tag HEAD) \
&& \
	air_lpwan_demo_date8=$$(cd "${<D}"  && git log --pretty='%cd' HEAD --date=short "HEAD~1..HEAD") \
&& \
	${RM} -rfv \
  ${air-lpwan-demo_dir}/.git \
  ${air-lpwan-demo_dir}/.gitmodules \
 > /dev/null 2>&1 \
&& \
	git add -f "${air-lpwan-demo_dir}" \
&& \
	msg=$$(printf "WIP: webthing: Import '$${air_lpwan_demo_tag}' ($${air_lpwan_demo_date8})\n\n\nOrigin: ${air-lpwan-demo_url}#${air-lpwan-demo_revision}\n") \
&& \
	git commit -sam "$${msg}"

air-lpwan-demo/del:
	rm -rf ${air-lpwan-demo_dir} 
	-git commit -am "WIP: webthing: About to replace import (${air-lpwan-demo_revision})"

air-lpwan-demo/import: air-lpwan-demo/del
	${MAKE} air-lpwan-demo/commit

${air-lpwan-demo_build_dir}: ${air-lpwan-demo_dir} ${air-lpwan-demo_self}
	@mkdir -p "$@"
	rsync -avx --delete "$</" "$@/"
	@-find "$@/" -iname '.git' -type d -prune -exec rm -rfv '{}' \; ||:
	@-find "$@/" -iname 'node_modules' -type d -prune -exec rm -rf '{}' \; ||:
	du -ks $@

air-lpwan-demo/build: ${contents_dir}/example/index.js ${air-lpwan-demo_build_dir}
	@ls $<

air-lpwan-demo/demo: air-lpwan-demo/help menuconfig air-lpwan-demo/build build run
	@echo "# log: Then run menuconfig to configure features"

${air-lpwan-demo_build_dir}/private/config.js: ${air-lpwan-demo_build_dir}/config.js
	@install -d ${@D}
	@ls $@ > /dev/null 2>&1 || cp -av $< $@ && echo "# log: Edit $@"
	@touch ${<D}

${contents_dir}/example/%.js: ${rules_dir}/${project_name}/%.js
	install -d ${@D}
	install $^ ${@D}
