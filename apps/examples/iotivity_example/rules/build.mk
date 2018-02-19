#! /usr/bin/make -f
# //******************************************************************
# //
# // Copyright 2014 Intel Corporation.
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

rule/task/%: rules/iotivity-config.mk
	${make} ${@F}

exe_args?=-v

package?=iotivity-example
local_bindir?=bin
local_optdir?=opt
install_dir?=${DESTDIR}/${local_optdir}/${package}/

-include rules/iotivity-config.mk
demo_time?=36000
TMPDIR?=${CURDIR}/tmp
log_dir?=${TMPDIR}/log
override platform?=default

user?=${USER}
deps+=rules/iotivity-config.mk
#export platform
arch?=$(shell uname -m || echo ${ARCH})
export V

rule/default: ${platform}/default

all: rules/iotivity-config.mk
	${make} ${platform}/$@

.PHONY: rule/%/% rule/print/% 

rule/print/%:
	@echo "# ${@F}=${${@F}}"


help: README.md
	@cat $<
	@echo "# Type make demo , client/server usage"
	@echo "# config_pkgconfig=${config_pkgconfig}"

longhelp: \
 rule/print/platform \
 rule/print/CPPFLAGS \
 rule/iotivity/longhelp \
 #eol

demo: demo/${platform}
	@echo "# $@: $^"

demo/%:
	${make} ${@F}/${@D}

demo/${platform}: demo/kill
	${make} platform=${@F} platform/demo &
	@echo "# please check it change state on server"
	sleep ${demo_time}
	@echo "# please check it change state on server"
	sleep ${demo_time}
	${make}	demo/kill


demo/all: distclean
	${make} platform=${platform} distclean
	${make} platform=${platform} demo


platform/demo: xterm/server xterm/client
	@echo "# $@: $^"

#include rules/iotivity.mk
include rules/${platform}.mk


install: ${all}
	install -d ${install_dir}/docs
	install LICENSE ${install_dir}/docs
	install README.md ${install_dir}/docs
	install -d ${install_dir}/bin
	install $^ ${install_dir}/bin

demo/kill: bin/server bin/client bin/observer
	-killall ${^F}

demo/check: demo/log
	grep "client_loop: gSwitch.value=1 (iterate)" ${log_dir}/client

demo/log: ${log_dir}/server  ${log_dir}/client
	grep "server.c:" ${log_dir}/server
	grep "client.c:" ${log_dir}/client


run/%: bin/%
	-killall ${@F}
	mkdir -p ${log_dir}
	stdbuf -oL -eL ${exe} \
 ${CURDIR}/${<D}/${<F} ${exe_args} \
 | tee ${log_dir}/${@F}


todo/run/%: bin/%
	-killall ${@F}
	mkdir -p ${log_dir}
	cd ${<D} && \
 LD_LIBRARY_PATH=. stdbuf -oL -eL ${exe} \
 ${CURDIR}/${<D}/${<F} ${exe_args} \
 | tee ${log_dir}/${@F}

xterm/% : bin/%
	xterm -T "$@" -e ${make} run/${@F}  &
	sleep 5

run: run/client
	@echo "# $@: $^"

platform/demo: xterm/server xterm/observer
	@echo "# $@: $^"

check: ${all}
	@echo "# $@: $^: TODO"

rebuild: cleanall all
	@echo "# $@: $^"

clean:
	find . -iname "*~" -exec rm '{}' \;
	find . -iname "*.o" -exec rm -v '{}' \;

cleanall: clean
	rm -rf bin rules/local.mk *.temp build* rules/*config.mk

distclean: ${platform}/cleanall cleanall
	-rm -rf build* tmp temp
	-${make} ${platform}/$@


deps: ${deps}
	@echo "# $@: $^"

-include rules/config.mk

rules/config.mk:
	touch $@


rules/iotivity-config.mk:
	touch $@
