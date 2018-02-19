# //******************************************************************
# //
# // Copyright 2016 Samsung Electronics France SAS All Rights Reserved.
# //
# //-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# //
# // Licensed under the Apache License, Version 2.0 (the "License");
# // you may not use this file except in compliance with the License.
# // You may obtain a copy of the License at
# //
# //      http://www.apache.org/licenses/LICENSE-2.0
# //
# // Unless required by applicable law or agreed to in writing, software
# // distributed under the License is distributed on an "AS IS" BASIS,
# // WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# // See the License for the specific language governing permissions and
# // limitations under the License.
# //
# //-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=


git?=git
export git

# Override here if needed
#iotivity_rel?=1.2-rel
#iotivity_version=${iotivity_rel}
#iotivity_src?=${HOME}/usr/local/src/

# Supported configurations
#iotivity_rel?=1.1-rel
#iotivity_version?=1.1.1

# Unsupported configurations
#iotivity_rel?=master
#iotivity_rel?=1.3-rel
#iotivity_version=1.3.0
#iotivity_rel?=1.1-rel
#iotivity_version=1.1.0
#iotivity_version=1.2.0

# Default configuration
iotivity_mode?=release
platform?=linux
TARGET_OS?=${platform}
iotivity_url?=http://github.com/iotivity/iotivity
iotivity_rel?=1.2-rel
iotivity_version?=1.2.1

export iotivity_version

tinycbor_url?=https://github.com/01org/tinycbor

include rules/iotivity-${iotivity_rel}.mk
# 
iotivity_libs?=\
 ${iotivity_out}/liboctbstack.a \
 ${iotivity_out}/libroutingmanager.a \
 ${iotivity_out}/libocsrm.a \
 ${iotivity_out}/liblogger.a \
 ${iotivity_out}/libconnectivity_abstraction.a \
 ${iotivity_out}/libc_common.a \
 ${iotivity_out}/libcoap.a \
 #eol

tinycbor_version?=v0.4.1
tinycbor_version?=master

gtest_url?=http://pkgs.fedoraproject.org/repo/pkgs/gtest/gtest-1.7.0.zip/2d6ec8ccdf5c46b05ba54a9fd1d130d7/gtest-1.7.0.zip

TMPDIR?=${CURDIR}/tmp
src_dir?=${TMPDIR}/iotivity/version/${iotivity_version}/platform/${platform}/src
override iotivity_dir?=${src_dir}/iotivity

iotivity_out?=${iotivity_dir}/out/${TARGET_OS}/${arch}/${iotivity_mode}

iotivity_cflags+=-DTB_LOG=1 -DROUTING_GATEWAY=1

iotivity_cflags+=\
 -I${iotivity_dir}/resource/c_common/ \
 -I${iotivity_dir}/resource/csdk/stack/include \
 -I${iotivity_dir}/resource/csdk/include \
 -I${iotivity_dir}/resource/csdk/logger/include \
 #eol

iotivity_cflags+=-I${iotivity_dir}/resource/stack

CPPFLAGS+=${iotivity_cflags}

all+=rule/iotivity/out

scons_flags+=LOGGING=0
scons_flags+=RELEASE=1
scons_flags+=ROUTING=EP 
scons_flags+=SECURED=0
scons_flags+=TARGET_TRANSPORT=IP
scons_flags+=VERBOSE=1 
scons_flags+=WITH_CLOUD=0
scons_flags+=WITH_PROXY=0
scons_flags+=WITH_TCP=0

git?=git
git_clone?=${git} clone --depth 1

${iotivity_dir}:
	@mkdir -p ${@D}
	${git_clone} ${iotivity_url} -b ${iotivity_version} ${@}
	ls $@ $^

#${iotivity_dir}/%: ${iotivity_dir}
#	ls $@

${iotivity_out}: rule/iotivity/build
#	ls $@ || ${MAKE} rule/iotivity/build
#	ls $@
	@echo "# $@: $^"

rule/iotivity/out: rule/print/iotivity_out ${iotivity_out}
	@echo "# $@: $^"

rule/iotivity/dir: rule/print/iotivity_dir ${iotivity_dir}

#rule/iotivity/out:
#	ls ${iotivity_out} || ${MAKE} platform=${platform} deps ${iotivity_out}
#	@echo "# $@: $^"


rule/iotivity/longhelp: \
 rule/print/iotivity_version \
 rule/print/iotivity_cflags \
 #eol


rule/iotivity/build: rule/iotivity/prepare rule/iotivity/scons

rule/iotivity/scons: ${iotivity_dir}
	cd ${iotivity_dir} && unset ARDUINO_HOME && scons ${scons_flags} resource
#	cd ${<} && ./auto_build.py ${platform} #TODO

rule/iotivity/clean:
	rm -rf ${iotivity_out} ${iotivity_dir}/.scon*

rule/gtest: ${iotivity_dir}/extlibs/gtest/gtest-1.7.0.zip
	@echo "# $@: $^"

${iotivity_dir}/extlibs/gtest/gtest-1.7.0.zip: ${iotivity_dir}
	[ -r "$@" ] || wget -c ${gtest_url} -O ${@}

${iotivity_dir}/extlibs/tinycbor/tinycbor: ${iotivity_dir}
	[ -r "$@" ] || ${git_clone} ${tinycbor_url} -b ${tinycbor_version} "$@"

rule/tinycbor: ${iotivity_dir}/extlibs/tinycbor/tinycbor
	@echo "# tinycbor_version=${tinycbor_version}"

rule/iotivity/prepare: rule/iotivity/prep rule/tinycbor rule/gtest

${iotivity_dir}/prep.sh: ${iotivity_dir}
	[ -r "$@" ] || touch "$@"

rule/iotivity/prep: ${iotivity_dir}/prep.sh
	cd ${<D} && EXEC_MODE=true bash -x ${<}

rule/iotivity/setup/debian: /etc/debian_version
	which apt-get
	which sudo || apt-get install sudo
	sudo apt-get install make psmisc wget git unp sudo aptitude xterm dos2unix
	sudo apt-get install uuid-dev
	sudo apt-get install libboost1.55-dev libboost1.55-all-dev libboost-thread1.55-dev \
	|| sudo apt-get install libboost-dev libboost-program-options-dev libexpat1-dev libboost-thread-dev

rule/iotivity/setup: rule/iotivity/setup/debian
	@echo "# $@: $^"


iotivity-config.mk:
	ls $(PKG_CONFIG_SYSROOT_DIR)/usr/lib*/pkgconfig/iotivity.pc && \
 echo "export config_pkgconfig=1" \
 || echo "export config_pkgconfig=0" > $@
	@echo "# type make help for usage"

${iotivity_libs}: ${iotivity_out}
	ls $@ $^

rule/iotivity/libs: rule/print/iotivity_libs ${iotivity_libs}

certs: dats

dat_files?=oic_svr_db_server.dat oic_svr_db_client_devowner.dat
json_files?=${dat_files:.dat=.json}

%.json: ${HOME}/mnt/iotivity/resource/csdk/stack/samples/linux/secure/%.json
	sed -e 's|/a/led|/BinarySwitch|g' < $< > $@

PATH+=:/usr/lib/iotivity/examples/

%.dat: %.json
	json2cbor $< $@

json: ${json_files}
	ls $^

dats: ${dat_files} 
	ls $^
