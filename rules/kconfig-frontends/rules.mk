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

kconfig_url?=https://github.com/TizenTeam/kconfig-frontends
kconfig_branch?=debian
sudo?=sudo
kconfig_dir?=${CURDIR}/tmp/kconfig-frontends

kconfig/setup/debian: rules/kconfig-frontends/rules.mk
	${sudo} apt-get update -y
	-apt-cache show kconfig-frontends && echo "TODO: install package $@" ||:
	${sudo} apt-get install -y dh-autoreconf sudo devscripts
	${sudo} apt-get install -y flex gperf libncurses5-dev # TODO
	${sudo} apt-get install -y bison pkg-config
	mkdir -p tmp
	cd ${kconfig_dir} || git clone ${kconfig_url} -b debian ${kconfig_dir}
	cd ${kconfig_dir} && ./debian/rules rule/debuild
	cd ${kconfig_dir} && ./debian/rules rule/debi

/usr/bin/kconfig-conf:
	ls $@ || ${MAKE} kconfig/setup/debian
	@ls $@

prep_files+=/usr/bin/kconfig-conf
