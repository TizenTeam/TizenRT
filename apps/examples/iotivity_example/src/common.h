// -*-c-*-
//******************************************************************
//
// Copyright 2014 Intel Mobile Communications GmbH All Rights Reserved.
// Copyright 2016 Samsung Electronics France SAS All Rights Reserved.
//
//-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

#ifndef common_h_
#define common_h_ __FILE__

#include <string.h>
#include <stdlib.h>
#include <stdbool.h>

#ifdef __linux__
#ifndef HAVE_STDIO_H
#define HAVE_STDIO_H 1
#endif
#ifndef HAVE_UNISTD_H
#define HAVE_UNISTD_H 1
#endif
#endif

#ifdef __TIZENRT__
#ifndef HAVE_STDIO_H
#define HAVE_STDIO_H 1
#endif
#endif


#ifdef HAVE_UNISTD_H
#include <unistd.h>
#else
// If platform is missing unistd.h
unsigned int sleep(unsigned int secs);
#endif

#include <ocstack.h>
#include <ocpayload.h>

#define STR(a) #a

#ifdef HAVE_STDIO_H
#include <stdio.h>
#define LOGf(f,p)                                                       \
    if (gVerbose)                                                       \
        printf("%s:%d: %s: %s=" f "\n",                                 \
                   __FILE__, __LINE__, __FUNCTION__,STR(p), p)
#else
#define LOGf(f,p)                               \
    if (gVerbose)                               \
        platform_log(__FUNCTION__)
#endif

static int gOver = 0;
static int gVerbose = 0;
static const int gDelay = 1;
static const char *gName = "oic.r.geolocation";
static const char *gUri = "/GeolocationResURI";
static char const *gIface = OC_RSRVD_INTERFACE_DEFAULT; //"oic.if.baseline"
static OCConnectivityType gConnectivityType = CT_DEFAULT;
static OCQualityOfService gQos = OC_LOW_QOS;


typedef struct GEOLOCATIONRESOURCE
{
    OCResourceHandle handle;
    double latitude;
    double longitude;
} GeolocationResource;

static GeolocationResource gResource = {NULL, 0, 0};


#endif // common_h_
