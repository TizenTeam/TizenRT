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

iotjs_modules_url=https://github.com/tizenteam/iotjs
iotjs_modules_branch?=sandbox/rzr/air-lpwan-demo/master
demo_dir?=external/iotjs_modules/air-lpwan-demo
private_dir?=${demo_dir}/private
#demo_dir?=.
prep_files+=${demo_dir}
prep_files+=${demo_dir}/index.js
contents_rules+=air-lpwan-demo/contents

${demo_dir}:
	mkdir -p ${@D}
	git clone -b ${iotjs_modules_branch} ${iotjs_modules_url} $@

${demo_dir}/%: ${demo_dir}
	ls $@

${demo_dir}/private/config.js: ${demo_dir}/config.js
	@mkdir -p ${@D}
	cp -av $< $@

devel/private:
	@mkdir -p ${demo_dir}/private
	rsync -avx ${HOME}/backup/${CURDIR}/${private_dir}/ ${private_dir}/ || echo "TODO"
	ls ${private_dir} 

private/rm:
	rm -rf ${CURDIR}/${demo_dir}/private

${contents_dir}/air-lpwan-demo: ${demo_dir} ${prep_files}
	rsync -avx --delete "$</" "$@/"
	rm -rf "$@/.git"
	rm -rf "$@/node_modules"

air-lpwan-demo/contents: ${contents_dir}/air-lpwan-demo
	ls $<
