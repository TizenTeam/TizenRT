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

top/mastodon-lite/default: mastodon-lite/default
	@echo "# $@: $^"

base_image_type?=iotjs
top_dir?=$(realpath ${CURDIR}/../..)
rules_dir?=${top_dir}/rules

# Declaration fragments
include ${rules_dir}/artik/config.mk
include ${rules_dir}/base/config.mk
include ${rules_dir}/${kernel}/decl.mk
include ${rules_dir}/${platform}/decl.mk
include ${rules_dir}/base/decl.mk
include ${rules_dir}/iotjs/decl.mk
include ${rules_dir}/webthing-iotjs/decl.mk
include ${rules_dir}/mastodon-lite/decl.mk

# Rules fragments
include ${rules_dir}/${platform}/rules.mk
include ${rules_dir}/${kernel}/rules.mk
include ${rules_dir}/base/rules.mk
include ${rules_dir}/base/extra.mk
include ${rules_dir}/base/setup.mk
include ${rules_dir}/iotjs/rules.mk
include ${rules_dir}/webthing-iotjs/rules.mk
include ${rules_dir}/mastodon-lite/rules.mk
