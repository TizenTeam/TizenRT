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

iotjs-express/default: help iotjs-express/build build
	@echo "# $@: $^"

iotjs-express/help:
	@echo "# iotjs-express"
	@echo "# URL: ${iotjs-express_url}#${iotjs-express_revision}"
	@echo "# Usage: Setup WiFi and flash then monitor"
	@echo "#  cd TizenRT"
	@echo "#  make -C rules/iotjs-express demo machine=${machine} tty=${tty}" 

${iotjs-express_dir}/.git:
	@rm -rf "${@D}.tmp"
	@mkdir -p "${@D}.tmp"
	git clone --recursive "${iotjs-express_url}" --branch "${iotjs-express_revision}" "${@D}.tmp" \
 || git clone --recursive "${iotjs-express_url}" "${@D}.tmp"
	cd "${@D}.tmp" \
 && git reset --hard "${iotjs-express_revision}" \
 || git reset --hard "remotes/origin/${iotjs-express_revision}"
	@-mv -f "${@D}" "${@D}.bak" > /dev/null 2>&1
	@mv "${@D}.tmp" "${@D}"
	@rm -rf "${@D}.bak"
	@ls $@


${iotjs-express_dir}:
	${MAKE} ${@}/.git

${iotjs-express_dir}/%: ${iotjs-express_dir}/.git
	ls $<

${iotjs-express_build_dir}: ${iotjs-express_dir} ${iotjs-express_self}
	@mkdir -p "$@"
	rsync -avx --delete "$</" "$@/"
	@-find "$@/" -iname '.git' -type d -prune -exec rm -rfv '{}' \; ||:
	@-find "$@/" -iname 'node_modules' -type d -prune -exec rm -rf '{}' \; ||:
	du -ks $@

iotjs-express/build: ${contents_dir}/example/index.js ${iotjs-express_build_dir}
	@ls $<

iotjs-express/demo: iotjs-express/help menuconfig iotjs-express/build build run
	@echo "#log: Then run menuconfig to configure wifi"

# TODO: refactor iotjs/rules.mk
${contents_dir}/example/index.js: ${iotjs-express_dir}/example/index.js
	install -d ${@D}
	install $^ ${@D}
