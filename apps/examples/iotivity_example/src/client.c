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

#ifdef __linux__
#ifndef HAVE_UNISTD_H
#define HAVE_UNISTD_H
#endif
#define HAVE_SIGNAL_H
#endif

#ifdef HAVE_SIGNAL_H
#include <signal.h>
#endif
#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif

#include <sys/ioctl.h>
#include <termios.h>

#include "common.h"


OCStackResult client_setup();
OCStackResult post();


unsigned int gDiscovered = 0;
static OCDevAddr gDestination;
int gObversable= 1;


OCRepPayload *createPayload()
{
    OCRepPayload *payload = OCRepPayloadCreate();

    LOGf("%p", payload);
    if (!payload)
    {
        exit(1);
    }

    LOGf("%.4f (changing)", gResource.latitude);
    OCRepPayloadSetPropDouble(payload, "latitude", gResource.latitude);
    OCRepPayloadSetPropDouble(payload, "longitude", gResource.longitude);

    LOGf("%.4f", gResource.latitude);
    return payload;
}


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
    OCRepPayload *payload = (OCRepPayload *)(clientResponse->payload);
    if (!payload)
    {
        LOGf("%p (error)", payload);
        return result;
    }

    if (!OCRepPayloadGetPropDouble(payload, "latitude", &gResource.latitude))
    {
        LOGf("%.4f (error)", gResource.latitude);
    }
    printf("%.4f\n", gResource.latitude);
    if (!OCRepPayloadGetPropDouble(payload, "longitude", &gResource.longitude))
    {
        LOGf("%.4f (error)", gResource.longitude);
    }
    printf("%.4f\n", gResource.longitude);

    LOGf("%.4f }", gResource.latitude);
    return OC_STACK_DELETE_TRANSACTION;
}


OCStackApplicationResult onGet(void *ctx,
                               OCDoHandle handle,
                               OCClientResponse *clientResponse)
{
    LOGf("%.4f {", gResource.latitude);
    OCStackApplicationResult result = OC_STACK_KEEP_TRANSACTION;

    LOGf("%p", clientResponse);
    if (!true)
        result = handleResponse(ctx, handle, clientResponse);
    if (result != OC_STACK_OK)
    {
        LOGf("%d (error)", result);
    }
    LOGf("%.4f }", gResource.latitude);
    return OC_STACK_DELETE_TRANSACTION;
}


OCStackResult get()
{
    LOGf("%.4f {", gResource.latitude);
    OCStackResult result = OC_STACK_OK;
    OCMethod method = OC_REST_GET;
    OCRepPayload *payload = NULL;
    OCCallbackData callback = {NULL, NULL, NULL};
    callback.cb = onGet;

    result = OCDoResource(&gResource.handle, method, gUri, &gDestination,
                          (OCPayload *) payload,
                          gConnectivityType, gQos, &callback, NULL, 0);

    if (result != OC_STACK_OK)
    {
        LOGf("%d", result);
    }
    LOGf("%.4f }", gResource.latitude);
    return result;
}


OCStackApplicationResult onPost(void *ctx,
                                OCDoHandle handle,
                                OCClientResponse *clientResponse)
{
    LOGf("%.4f {", gResource.latitude);
    OCStackApplicationResult result = OC_STACK_KEEP_TRANSACTION;

    LOGf("%p", clientResponse);
    result = handleResponse(ctx, handle, clientResponse);

    LOGf("%d", result);
    LOGf("%.4f }", gResource.latitude);
    return OC_STACK_DELETE_TRANSACTION;
}


OCStackResult post()
{
    LOGf("%.4f {", gResource.latitude);
    OCStackResult result = OC_STACK_OK;
    OCMethod method = OC_REST_POST;
    OCRepPayload *payload = NULL;
    OCCallbackData callback = {NULL, NULL, NULL};
    callback.cb = onPost;

    LOGf("%.4f", gResource.latitude);
    gResource.latitude = !gResource.latitude;
    payload = createPayload();

    result = OCDoResource(&gResource.handle, method, gUri, &gDestination,
                          (OCPayload *) payload,
                          gConnectivityType, gQos, &callback, NULL, 0);

    if (result != OC_STACK_OK)
    {
        LOGf("%d", result);
    }
    LOGf("%.4f }", gResource.latitude);
    return result;
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


int kbhit()
{
    struct termios term, oterm;
    int fd = 0;
    int c = 0;
    tcgetattr(fd, &oterm);
    memcpy(&term, &oterm, sizeof(term));
    term.c_lflag = term.c_lflag & (!ICANON);
    term.c_cc[VMIN] = 0;
    term.c_cc[VTIME] = 1;
    tcsetattr(fd, TCSANOW, &term);
    c = getchar();
    tcsetattr(fd, TCSANOW, &oterm);
    return (c);
}


OCStackResult client_loop()
{
    OCStackResult result;
    LOGf("%.4f (iterate)", gResource.latitude);

    result = OCProcess();
    if (result != OC_STACK_OK)
    {
        LOGf("%d (error)", result);
        return result;
    }

    static int once = 1;
    if (gDiscovered && once-- > 0)
    {
        sleep(4 * gDelay);
        result = post();
        LOGf("%d (post)", result);
    }
    int c = 0;
    if (gDiscovered && ((c = kbhit()) > 0))
    {
        LOGf("%d (post on kbhit)", c);
        result = post();
    }
    sleep(gDelay);
    LOGf("%d", gOver);
    return result;
}


OCStackResult client_setup()
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
                              NULL, // destination
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


void client_finish()
{
    OCStackResult result = OCStop();

    if (result != OC_STACK_OK)
    {
        LOGf("%d (error)", result);
    }
}


/* SIGINT handler: set gOver to 1 for graceful termination */
void onSignal(int signum)
{
    if (signum == SIGINT)
    {
        gOver = 1;
    }
}


int client_main(int argc, char *argv[])
{
    if (argc>1 && (0 == strcmp("-v", argv[1])))
    {
        gVerbose++;
    }
    LOGf("%d", gVerbose);
    LOGf("%s", "Break from loop with Ctrl+C");
    signal(SIGINT, onSignal);

    client_setup();

    for (; !gOver;)
    {
        client_loop();
    }
    client_finish();
    return 0;
}


int main(int argc, char *argv[])
{
    return client_main(argc, argv);
}
