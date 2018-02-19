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

default/default: default/all
	date

config_pkgconfig?=1
PKG_CONFIG?=pkg-config

ifeq (${config_pkgconfig},1)
iotivity_dir?=$(PKG_CONFIG_SYSROOT_DIR)/usr/include/iotivity
iotivity_out?=$(PKG_CONFIG_SYSROOT_DIR)/usr/lib
iotivity_cflags+=$(shell ${PKG_CONFIG} --cflags iotivity)
iotivity_libs+=$(shell ${PKG_CONFIG} --libs iotivity)
# TODO: workaround for 1.2.0
#iotivity_cflags+=-I${iotivity_dir}/resource/stack
#iotivity_cflags+=-I${iotivity_dir}/..
# TODO: workaround for 1.2-rel
#iotivity_libs+=-luuid
#iotivity_libs+=-lpthread
#iotivity_libs+=-lm
else
include rules/iotivity.mk
LDFLAGS+=-L${iotivity_out}
iotivity_libs+=-loctbstack
iotivity_libs+=-lconnectivity_abstraction
iotivity_libs+=-loc_logger
iotivity_libs+=-luuid
iotivity_libs+=-lpthread
iotivity_libs+=-lm
iotivity_cflags+=-pthread 
endif

CPPFLAGS+=${iotivity_cflags}
LIBS+=${iotivity_libs}

CFLAGS+=-fPIC
CPPFLAGS+=-Isrc

server_objs?=src/server/platform/default/platform.o
server?=${local_bindir}/server

client?=${local_bindir}/client
client_objs?=

observer?=${local_bindir}/observer
observer_objs?=


all+=${server}
all+=${client}
all+=${observer}


default/all: ${all}
	@echo "# $@: $^"

default/clean:
	-rm -f *.o *~ ${objs} */*.o

default/cleanall: default/clean
	-rm -rf bin
	-rm -f *.o *~ ${objs} */*.o

default/distclean: default/cleanall
	rm -rf typescript build*
	rm -f ${client} ${server}

${local_bindir}/server: src/server.o ${server_objs} ${objs} ${libs}
	@-mkdir -p ${@D}
	${CC} -o ${@} $^ ${LDFLAGS} ${LIBS}

${local_bindir}/client: src/client.o ${client_objs} ${objs} ${libs}
	@-mkdir -p ${@D}
	${CC} -o ${@} $^ ${LDFLAGS} ${LIBS}

${local_bindir}/observer: src/observer.o ${client_objs} ${objs} ${libs}
	@-mkdir -p ${@D}
	${CC} -o ${@} $^ ${LDFLAGS} ${LIBS}

${local_bindir}/%: %.o ${objs}
	@-mkdir -p ${@D}
	${CC} -o ${@} $^ ${LDFLAGS} ${LIBS}

${platform}/demo: platform/demo
	@echo "# $@: $^"
