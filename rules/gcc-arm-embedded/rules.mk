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

-include ${rules_dir}/gcc-arm-embedded/decl.mk

${toolchain_dir}:
	@echo "# log: Installing toolchain: ${@}"
	@rm -rf ${@}.tmp
	@mkdir -p ${@}.tmp
	curl -sL ${toolchain_url} | tar xj -C ${@}.tmp
	@mkdir -p ${@D}
	@mv ${@}.tmp/${@F} ${@}
	@ls $@ 
	@ls ${toolchain_bin}
	@ls ${CC}
	-file ${CC}
	${CC} --version

${toolchain_dir}/%: ${toolchain_dir}
	@ls $@

gcc-arm-embedded/setup: ${CC}
	$< --version

gcc-arm-embedded/setup/debian: ${CC}
	sudo apt-get install -y curl libc6-i386 \
 || sudo apt-get install -y curl libc6
