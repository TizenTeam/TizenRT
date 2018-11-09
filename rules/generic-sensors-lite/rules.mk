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

generic-sensors-lite/default: help generic-sensors-lite/build build
	@echo "# $@: $^"

generic-sensors-lite/help:
	@echo "# generic-sensors-lite"
	@echo "# Description: WebOfThing node for Mozilla IoT gateway using IoT.js"
	@echo "# URL: ${generic-sensors-lite_url}#${generic-sensors-lite_revision}"
	@echo "# Usage: Setup WiFi and flash then monitor"
	@echo "#  cd TizenRT"
	@echo "#  make -C rules/generic-sensors-lite demo machine=${machine} tty=${tty}" 

${generic-sensors-lite_dir}/.git:
	@rm -rf "${@D}.tmp"
	@mkdir -p "${@D}.tmp"
	git clone --recursive "${generic-sensors-lite_url}" --branch "${generic-sensors-lite_revision}" "${@D}.tmp" \
 || 	git clone --recursive "${generic-sensors-lite_url}" "${@D}.tmp"
	cd "${@D}.tmp" \
 && git reset --hard "${generic-sensors-lite_revision}" \
 || git reset --hard "remotes/origin/${generic-sensors-lite_revision}"
	@-mv -f "${@D}" "${@D}.bak" > /dev/null 2>&1
	@mv "${@D}.tmp" "${@D}"
	@rm -rf "${@D}.bak"
	@ls $@

${generic-sensors-lite_dir}/iotjs_modules/%: ${generic-sensors-lite_dir}/iotjs_modules
	ls $@

${generic-sensors-lite_dir}/iotjs_modules:${generic-sensors-lite_dir}
	make -C "$<" runtime=iotjs setup/iotjs
	ls $@

${generic-sensors-lite_dir}:
	ls $@ >/dev/null 2>&1 || ${MAKE} ${generic-sensors-lite_dir}/.git

generic-sensors-lite/commit: ${generic-sensors-lite_dir}/.git
	cd "${generic-sensors-lite_dir}" && git describe --tag HEAD
	-cd "${<D}" && git log --pretty='%cd' HEAD --date=short "HEAD~1..HEAD" ||:
	generic_sensors_lite_tag=$$(cd "${<D}" && git describe --tag HEAD) \
&& \
	generic_sensors_lite_date8=$$(cd "${<D}"  && git log --pretty='%cd' HEAD --date=short "HEAD~1..HEAD") \
&& \
	${RM} -rfv \
  ${generic-sensors-lite_dir}/.git \
  ${generic-sensors-lite_dir}/.gitmodules \
 > /dev/null 2>&1 \
&& \
	git add -f "${generic-sensors-lite_dir}" \
&& \
	msg=$$(printf "WIP: webthing: Import '$${generic_sensors_lite_tag}' ($${generic_sensors_lite_date8})\n\n\nOrigin: ${generic-sensors-lite_url}#${generic-sensors-lite_revision}\n") \
&& \
	git commit -sam "$${msg}"

generic-sensors-lite/del:
	rm -rf ${generic-sensors-lite_dir} 
	-git commit -am "WIP: webthing: About to replace import (${generic-sensors-lite_revision})"

generic-sensors-lite/import: generic-sensors-lite/del
	${MAKE} generic-sensors-lite/commit

${iotjs_modules_dir}: ${generic-sensors-lite_dir}/iotjs_modules
	@mkdir -p "$@"
	rsync -avx --delete "$</" "$@/"
	@-find "$@/" -iname '.git' -type d -prune -exec rm -rfv '{}' \; ||:

${iotjs_modules_dir}/%: ${iotjs_modules_dir} ${generic-sensors-lite_dir}/iotjs_modules 
	mkdir -p "$@"
	rsync -avx --delete "${generic-sensors-lite_dir}/iotjs_modules/${@F}/" "$@/"
	@-find "$@/" -iname '.git' -type d -prune -exec rm -rfv '{}' \; ||:
	ls $@

${generic-sensors-lite_build_dir}: ${generic-sensors-lite_dir} ${generic-sensors-lite_self}
	@mkdir -p "$@"
	rsync -avx --delete --exclude 'iotjs_modules/' "$</" "$@/"
	@-find "$@/" -iname '.git' -type d -prune -exec rm -rfv '{}' \; ||:
	@-find "$@/" -iname 'node_modules' -type d -prune -exec rm -rf '{}' \; ||:
	du -ks $@

generic-sensors-lite/build: ${contents_dir}/example/index.js ${generic-sensors-lite_build_dir}
	@ls $<

generic-sensors-lite/demo: generic-sensors-lite/help menuconfig generic-sensors-lite/build build run
	@echo "# log: Then run menuconfig to configure features"

${contents_dir}/example/%.js: ${rules_dir}/${project_name}/%.js
	install -d ${@D}
	install $^ ${@D}
