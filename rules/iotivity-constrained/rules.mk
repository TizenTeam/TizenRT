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


iotivity_constrained_dir?=external/iotivity-constrained
iotivity_constrained_url?=https://github.com/tizenteam/iotivity-constrained
iotivity_constrained_branch?=sandbox/rzr/tizenrt/master

iotivity_constrained_prep_files?=apps/examples/iotivity_constrained_example
prep_files+=${iotivity_constrained_prep_files}

iotivity-constrained/rm:
	rm -rf ${iotivity_constrained_dir}
	-git commit -am 'WIP: iotivity-constrained: About to replace with upstream'

iotivity-constrained/clone: ${iotivity_constrained_dir}
	ls $<

${iotivity_constrained_dir}:
	git clone --recursive -b ${iotivity_constrained_branch} \
  ${iotivity_constrained_url} ${iotivity_constrained_dir}
# TODO: --depth 1

${iotivity_constrained_dir}/%: ${iotivity_constrained_dir}
	ls $@

iotivity-constrained/sync: iotivity-constrained/rm iotivity-constrained/import

iotivity-constrained/import: ${iotivity_constrained_dir}
	rm -rfv ${iotivity_constrained_dir}/.git  ${iotivity_constrained_dir}/.gitmodules \
	 ${iotivity_constrained_dir}/deps/*/.git  ${iotivity_constrained_dir}/deps/*/*.gitmodules 
	git add ${iotivity_constrained_dir}
	git commit -am "WIP: iotivity-constrained: Import (${iotivity_constrained_branch})"
#	git checkout HEAD~2 external/iotivity/Kconfig
#	git commit -am 'WIP: iotivity: Reverted Kconfig.runtime'


iotivity-constrained/prep: ${iotivity_constrained_prep_files}

${iotivity_constrained_dir}/Kconfig:

iotivity-constrained/setup/debian:
	sudo apt-get install -y make

iotivity-constrained/build:
	${MAKE} -C external/iotivity-constrained/tests/port/tizenrt os_dir="${PWD}"


apps/examples/iotivity_constrained_example: ${iotivity_constrained_dir}/tests/port/tizenrt/examples/iotivity_constrained_example
	cp -rfva $< $@
