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

project_name?=iotjs-express
top_dir?=${CURDIR}
rules_dir?=${top_dir}/rules
platform?=artik
machine?=${platform}053s

iotjs-express_url?=https://github.com/SamsungInternet/iotjs-express
iotjs-express_revision?=v0.0.3
iotjs-express_dir?=${top_dir}/external/iotjs-express
iotjs-express_build_dir?=${contents_dir}/example/iotjs_modules/iotjs-express
contents_rules+=${iotjs-express_build_dir}
contents_rules+=${contents_dir}/example/index.js

# TODO: Use current iotjs and then try servers ws
iotjs_prep_files+=${iotjs_dir}/src/modules/iotjs_module_websocket.h

# Override iotjs decl
iotjs_example_dir=${iotjs-express_dir}/example