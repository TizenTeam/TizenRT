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

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>

#include <ocstack.h>
#include <ocpayload.h>

#include "common.h"

OCStackResult server_setup();
OCStackResult server_loop();
OCStackResult server_finish();

void platform_log(char const *);
void platform_setup();
void platform_loop();
void platform_setValue(bool value);

OCStackResult createResource();


OCStackResult setValue(double latitude, double longitude)
{
    OCStackResult result;
    LOGf("%.4f", latitude);
    gResource.latitude = latitude;
    gResource.longitude = longitude;

    result = OCNotifyAllObservers(gResource.handle, gQos);
    return result;
}


OCRepPayload *createPayload()
{
    OCRepPayload *payload = OCRepPayloadCreate();

    LOGf("%p", payload);
    if (!payload)
    {
        exit(1);
    }
    //OCRepPayloadAddResourceType(payload, gIface);
    //OCRepPayloadAddInterface(payload, DEFAULT_INTERFACE);

    LOGf("%.4f (payload)", gResource.latitude);
    OCRepPayloadSetPropDouble(payload, "latitude", gResource.latitude);
    OCRepPayloadSetPropDouble(payload, "longitude", gResource.longitude);

    return payload;
}


OCEntityHandlerResult onOCEntity(OCEntityHandlerFlag flag,
                                 OCEntityHandlerRequest *entityHandlerRequest,
                                 void *callbackParam)
{
    OCEntityHandlerResult result = OC_EH_OK;
    OCStackResult res = OC_STACK_OK;
    OCRepPayload *payload = NULL;
    OCEntityHandlerResponse response = {0};
    memset(&response,0,sizeof response);

    LOGf("%p", entityHandlerRequest);
    LOGf("%.4f (current)", gResource.latitude);

    if (entityHandlerRequest && (flag & OC_REQUEST_FLAG))
    {
        LOGf("%d", entityHandlerRequest->method);
        OCRepPayload* input = NULL;
        switch (entityHandlerRequest->method)
        {
        case OC_REST_POST:
        case OC_REST_PUT:
            input = (OCRepPayload*) entityHandlerRequest->payload;
            OCRepPayloadGetPropDouble(input, "latitude", &gResource.latitude);
            OCRepPayloadGetPropDouble(input, "longitude", &gResource.longitude);
            LOGf("%.4f (update)", gResource.latitude);
            LOGf("%.4f (update)", gResource.longitude);
            res = setValue(gResource.latitude, gResource.longitude);
            break;
        case OC_REST_GET:
            OCRepPayloadSetUri(payload, gUri);
            OCRepPayloadSetPropDouble(payload, "latitude", gResource.latitude);
            OCRepPayloadSetPropDouble(payload, "longitude", gResource.longitude);
            break;
        default:
            break;
        }
        payload = (OCRepPayload *) createPayload();
        if (!payload)
        {
            LOGf("%p (error)", payload);
            return OC_EH_ERROR;
        }
        response.payload = (OCPayload *) payload;

        response.ehResult = result;
        response.numSendVendorSpecificHeaderOptions = 0;
        memset(response.sendVendorSpecificHeaderOptions, 0,
               sizeof response.sendVendorSpecificHeaderOptions);

        memset(response.resourceUri, 0, sizeof response.resourceUri);
        response.persistentBufferFlag = 0;
        response.requestHandle = entityHandlerRequest->requestHandle;
        response.resourceHandle = entityHandlerRequest->resource;
        LOGf("%p (note request infos are copied)", response.resourceHandle);

        res = OCDoResponse(&response);
        if (res != OC_STACK_OK)
        {
            LOGf("%d (error)", res);
            result = OC_EH_ERROR;
        }
        OCRepPayloadDestroy(payload);
    }
    return result;
}


OCStackResult createResource()
{
    OCStackResult result = OCCreateResource(&(gResource.handle),
                                            gName,
                                            gIface,
                                            gUri,
                                            onOCEntity,
                                            NULL,
                                            OC_DISCOVERABLE|OC_OBSERVABLE);
    LOGf("%s", gIface );
    LOGf("%d", result);
    return result;
}


OCStackResult server_loop()
{
    LOGf("%.4f (iterate)", gResource.latitude);

    static double m_lat = 48.1033;
    static double m_lon = -1.6725;
    static double m_offset = 0.001;

    static double m_latmax = 49;
    static double m_latmin = 48;

    m_lat += m_offset;
    m_lon += m_offset;
    
    if (m_lat > m_latmax)
    {
        if (m_offset > 0) { m_offset = - m_offset; }
    }
    else if (m_lat < m_latmin)
    {
        if ( m_offset < 0 ) { m_offset = - m_offset; }
    }
    
    setValue( m_lat, m_lon);
    OCStackResult result = OCProcess();
    if (result != OC_STACK_OK)
    {
        LOGf("%d (error)", result);
        return result;
    }

    sleep(gDelay);
    return result;
}


OCStackResult server_setup()
{
    OCStackResult result;
    result = OCInit(NULL, 0, OC_SERVER);
    if (result != OC_STACK_OK)
    {
        LOGf("%d (error)", result);
        return result;
    }

    result = createResource();
    if (result != OC_STACK_OK)
    {
        LOGf("%d (error)", result);
        return result;
    }

    LOGf("%d", result);
    return result;
}


OCStackResult server_finish()
{
    OCStackResult result = OCStop();
    if (result != OC_STACK_OK)
    {
        LOGf("%d (error)", result);
    }
    return result;
}


int server_main(int argc, char* argv[])
{
    OCStackResult result;    
    if (argc>1 && (0 == strcmp("-v", argv[1])))
    {
        gVerbose++;
    }
    result = server_setup();

    if (result != 0)
    {
        return result;
    }

    while (!gOver)
    {
        result = server_loop();
    }

    server_finish();

    return (int) result ;
}
