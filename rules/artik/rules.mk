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

artik/help: ${configs_dir}/${machine}/README.md ${rules_dir}/${platform}/decl.mk ${rules_dir}/${platform}/rules.mk
	-cat $<

artik/image: ${deploy_image}
	@ls -l $^

artik/download: ${deploy_image} ${contents_dir} ${os_dir}
	@echo "# log: Clean in ${contents_dir} to save flash for ${machine}"
	@-find "${contents_dir}/" -iname '.git' -type d -prune -exec rm -rfv {} \;
	@-du -ks ${contents_dir}
	@ls -l /dev/ttyUSB*
	${MAKE} -C ${os_dir} ${@F} ALL
	@ls -l /dev/ttyUSB*

artik/deploy: artik/download
	@echo "# log: $@: $^"

artik/run: monitor
	@echo "# log: $@: $^"

artik/setup/debian:
	sudo apt-get install -y genromfs openocd

artik/demo: artik/help
	${MAKE} -e prep
	${MAKE} -e configure
	${MAKE} -e deploy
	${MAKE} -e run

include ${rules_dir}/${toolchain}/rules.mk

.PHONY: artik/download
