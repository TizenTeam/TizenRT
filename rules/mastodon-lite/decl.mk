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

project_name?=mastodon-lite
top_dir?=${CURDIR}
rules_dir?=${top_dir}/rules
platform?=artik
machine?=${platform}055s

mastodon-lite_url?=https://github.com/rzr/mastodon-lite
# TODO: Pin latest version
#mastodon-lite_revision?=mastodon-lite-0.7.0
mastodon-lite_revision?=master
mastodon-lite_dir?=${top_dir}/external/mastodon-lite
mastodon-lite_build_dir?=${contents_dir}/example/iotjs_modules/mastodon-lite
mastodon-lite_js_file?=${rules_dir}/mastodon-lite/index.js
contents_rules+=${mastodon-lite_build_dir}
contents_rules+=${contents_dir}/example/index.js
#contents_rules+=${contents_dir}/example/webthing.js
contents_rules+=${contents_dir}/.mastodon-lite.json
# TODO: Use current iotjs and then try servers ws
iotjs_prep_files+=${iotjs_dir}/src/modules/iotjs_module_websocket.h
