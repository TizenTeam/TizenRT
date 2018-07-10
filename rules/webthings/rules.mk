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

webthings_self?=rules/webthings/rules.mk
webthings_branch?=sandbox/rzr/devel/iotjs/tizenrt/master
webthings_url?=https://github.com/tizenteam/webthing-node
webthings_dir?=external/webthing-node
contents_dir?=tools/fs/contents
contents_rules+=webthings/contents

webthings/contents: ${contents_dir}/webthing-node
	ls $<

${webthings_dir}:
	mkdir -p $@
	git clone --recursive --depth 1 ${webthings_url} -b ${webthings_branch} $@

${contents_dir}/webthing-node: ${webthings_dir} ${webthings_self}
	rsync -avx --delete "$</" "$@/"
	rm -rf "$@/.git"
	rm -rf "$@/node_modules"

webthings/home: ${HOME}/mnt/webthing-node
	rsync -avx "${HOME}/mnt/webthing-node/" "${contents_dir}/webthing-node" 
	rm -rf "${contents_dir}/webthing-node/.git"
	rm -rf "${contents_dir}/webthing-node/node_modules"
