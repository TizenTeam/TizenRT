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

include rules/default.mk
platform=linux

ifeq (${PLATFORM}, TIZEN)
CPPFLAGS+=-D__TIZEN__=1 
CPPFLAGS+=$(shell pkg-config dlog --cflags)
LIBS+=$(shell pkg-config dlog --libs)
endif
scons_flags+=TARGET_OS=linux TARGET_ARCH=${arch}

# For artik10
#CPPFLAGS+=-DCONFIG_GPIO=22
#CPPFLAGS+=-DCONFIG_WANT_GPIO=1
server_objs+=src/server/platform/${platform}/platform.o

OSTYPE?=$(shell echo "$${OSTYPE}")
uname?=$(shell echo `uname -s` || echo "")

TARGET_OS?=${uname}
ifeq ("",${TARGET_OS})
TARGET_OS=${OSTYPE}
endif

ifeq ("linux-gnu","${TARGET_OS}")
TARGET_OS=linux
endif
ifeq ("Linux","${TARGET_OS}")
TARGET_OS=linux
endif

linux/default: default/default
