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
#include <stdlib.h>
#include <string.h>
#include <octypes.h>
#include <ocstack.h>
#include <ocpayload.h>

#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif

#include "common.h"


OCStackResult observer_setup();


unsigned int gDiscovered = 0;
static OCDevAddr gDestination;
int gObversable = 1;


OCStackApplicationResult handleResponse(void *ctx,
                                        OCDoHandle handle,
                                        OCClientResponse *clientResponse)
{
    LOGf("%.4f {", gResource.latitude);
    OCStackApplicationResult result = OC_STACK_DELETE_TRANSACTION;

    if (!clientResponse)
    {
        LOGf("%p (error)", clientResponse);
        return result;
    }
    LOGf("%d\n", clientResponse->result);
    OCRepPayload *payload = (OCRepPayload *)(clientResponse->payload);
    if (!payload)
    {
        LOGf("%p (error)", payload);
        return result;
    }
    if (!OCRepPayloadGetPropDouble(payload, "latitude", &gResource.latitude))
    {
        LOGf("%f (error) GetProp", gResource.latitude);
    }

    if (!OCRepPayloadGetPropDouble(payload, "longitude", &gResource.longitude))
    {
        LOGf("%f (error) GetProp", gResource.longitude);
    }
    //printf("%x, %x\n", gResource.latitude, gResource.longitude);
    printf("{%s: {latitude: %.4f, longitude: %.4f }}\n", 
           gName, gResource.latitude, gResource.longitude);
    
    FILE * file = fopen("/mnt/gps", "w");
    if ( file ) {
        fprintf(file, "{%s: {latitude: %.4f, longitude: %.4f }}\n", 
                gName, gResource.latitude, gResource.longitude);
        fclose(file);
    }
        
    LOGf("%.4f }", gResource.latitude);
    return OC_STACK_DELETE_TRANSACTION;
}


OCStackApplicationResult onObserve(void* ctx, 
                                   OCDoHandle handle,
                                   OCClientResponse * clientResponse)
{
    LOGf("%.4f {", gResource.latitude);
    OCStackApplicationResult result = OC_STACK_KEEP_TRANSACTION;

    LOGf("%p", clientResponse);
    result = handleResponse(ctx, handle, clientResponse);

    LOGf("%d", result);
    LOGf("%.4f }", gResource.latitude);
    return OC_STACK_KEEP_TRANSACTION;
}


// This is a function called back when a device is discovered
OCStackApplicationResult onDiscover(void *ctx,
                                    OCDoHandle handle,
                                    OCClientResponse *clientResponse)
{
    OCStackResult result = OC_STACK_OK;

    LOGf("%p", ctx);
    LOGf("%p", clientResponse);

    if (!clientResponse)
    {
        return OC_STACK_DELETE_TRANSACTION;
    }

    LOGf("%p", clientResponse->devAddr.addr);
    LOGf("%d", clientResponse->sequenceNumber);
    LOGf("%p", clientResponse->payload);
    OCDiscoveryPayload *payload = (OCDiscoveryPayload *) clientResponse->payload;
    LOGf("%p", payload);
    gDiscovered++;
    if (!payload)
    {
        return OC_STACK_DELETE_TRANSACTION;
    }

    OCResourcePayload *resource = (OCResourcePayload *) payload->resources;

    while (resource)
    {
        LOGf("%p", resource);
        if (resource->uri)
        {
            LOGf("%s", resource->uri);
            if (0 == strcmp(gUri, resource->uri))
            {
                gDestination = clientResponse->devAddr;
                LOGf("%s", gDestination.addr);
                gConnectivityType = clientResponse->connType;
                gResource.handle = handle;
                if (gObversable)
                {
                    OCCallbackData callback = {NULL, NULL, NULL};
                    callback.cb = onObserve;
                    OCStackResult ret;
                    ret = OCDoResource(&gResource.handle, OC_REST_OBSERVE,
                                       gUri, &gDestination, NULL,
                                       gConnectivityType, gQos, &callback, NULL, 0);
                }
            }
        }
        resource = resource->next;
    }

    return OC_STACK_KEEP_TRANSACTION;
}


OCStackResult observer_loop()
{
    OCStackResult result;
    static int iterations = 0;
    LOGf("%d (iterate)", ++iterations);
    if (false) { //for tests
        if ( 16 <= iterations ) { gOver = true; } //TODO
    }

    result = OCProcess();
    if (result != OC_STACK_OK)
    {
        LOGf("%d (error)", result);
        return result;
    }

    int c = 0;
    sleep(gDelay);
    LOGf("%d", gOver);
    return result;
}


OCStackResult observer_setup()
{
    int i = 0;
    OCStackResult result;
    static int gInit = 0;
    if (gInit++ == 0)
    {
        result = OCInit1(OC_CLIENT, // or OC_CLIENT_SERVER,
                         OC_DEFAULT_FLAGS, OC_DEFAULT_FLAGS);

        if (result != OC_STACK_OK)
        {
            LOGf("%d (error)", result);
            return result;
        }
    }

    OCCallbackData cbData = {NULL, NULL, NULL};
    cbData.cb = onDiscover;
    LOGf("%p", cbData.cb);
    char queryUri[MAX_QUERY_LENGTH] = { 0 };
    snprintf(queryUri, sizeof (queryUri), "%s", OC_RSRVD_WELL_KNOWN_URI);
    LOGf("%s", queryUri);

    for (i = 0; !gDiscovered && i < 2; i++)
    {
        LOGf("%d", gDiscovered);

        result = OCDoResource(NULL, // handle
                              OC_REST_DISCOVER, // method
                              queryUri, //requestUri: /oic/res
                              NULL, // destination_p
                              NULL,  // opayload
                              gConnectivityType, //
                              gQos, // OC_LOW_QOS
                              &cbData, //
                              NULL, // options
                              0 // numOptions
                             );

        if (result != OC_STACK_OK)
        {
            LOGf("%d (error)", result);
        }

        sleep(1 * gDelay);
    }
    LOGf("%d", result);
    return result;
}


void observer_finish()
{
    OCStackResult result = OCStop();

    if (result != OC_STACK_OK)
    {
        LOGf("%d (error)", result);
    }
}


int observer_main(int argc, char *argv[])
{
    if (argc>1 && (0 == strcmp("-v", argv[1])))
    {
        gVerbose++;
    }
    LOGf("%d", gVerbose);
 
    observer_setup();

    for (; !gOver;)
    {
        observer_loop();
    }
    observer_finish();
    return 0;
}

#ifndef __TIZENRT__
int main(int argc, char *argv[])
{
    return observer_main(argc, argv);
}
#endif
