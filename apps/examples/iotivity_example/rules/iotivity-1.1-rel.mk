tinycbor_version?=v0.2.1
iotivity_libs?=\
 ${iotivity_out}/liboctbstack.a \
 ${iotivity_out}/resource/csdk/routing/libroutingmanager.a \
 ${iotivity_out}/libocsrm.a \
 ${iotivity_out}/resource/csdk/logger/liblogger.a \
 ${iotivity_out}/libconnectivity_abstraction.a \
 ${iotivity_out}/resource/c_common/libc_common.a \
 ${iotivity_out}/libcoap.a \
 #eol

#TODO: resource/c_common/platform_features.h:38:27: fatal error: stdassert.h: No such file or directory
