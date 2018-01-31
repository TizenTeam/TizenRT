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


iotjs_dir?=external/iotjs
iotjs_url?=https://github.com/Samsung/iotjs
iotjs_branch?=master

${iotjs_dir}/deps/%: 
	ls ${iotjs_dir}/.git ${iotjs_dir}/.gitmodules
	cd ${iotjs_dir} && git submodule update --init --recursive 

iotjs/deps: ${iotjs_dir}/deps/jerry/CMakeLists.txt
	ls $<

${iotjs_dir}:
	git clone -b "${iotjs_branch}" --recursive --depth 1 ${iotjs_url} ${iotjs_dir}

${iotjs_dir}/%: ${iotjs_dir}
	@ls $@

iotjs/prep: ${iotjs_dir} iotjs/deps
	@ls -l ${iotjs_dir}/Kconfig.runtime

iotjs/rm:
	rm -rf ${iotjs_dir} 
	-git commit -am 'WIP: iotjs: About to replace import (${iotjs_branch})'

iotjs/import: iotjs/rm 
	${make} iotjs/prep
	${RM} -rfv ${iotjs_dir}/.git ${iotjs_dir}/.gitmodules \
 ${iotjs_dir}/deps/*/.git ${iotjs_dir}/deps/*/*.gitmodules
	git add -f ${iotjs_dir}
	git commit -am 'WIP: iotjs: import sync (${iotjs_branch})'
#	-git checkout HEAD~2 external/iotjs/Kconfig.runtime
#	-git commit -am 'WIP: iotjs: Reverted Kconfig.runtime'
