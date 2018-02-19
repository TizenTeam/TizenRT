ifeq (${iotivity_version}, 1.2.0)
tinycbor_version?=v0.3.1
iotivity_cflags+=-I${iotivity_dir}/extlibs/tinycbor/tinycbor/src/
endif

tinycbor_version?=v0.4

iotivity_libs?=\
 ${iotivity_out}/liboctbstack.a \
 ${iotivity_out}/resource/csdk/routing/libroutingmanager.a \
 ${iotivity_out}/libocsrm.a \
 ${iotivity_out}/resource/csdk/logger/liblogger.a \
 ${iotivity_out}/libconnectivity_abstraction.a \
 ${iotivity_out}/resource/c_common/libc_common.a \
 ${iotivity_out}/libcoap.a \
 #eol
