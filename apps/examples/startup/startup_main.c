// -*- mode: c++;  c-basic-offset: 4 -*-
/****************************************************************************
 *
 * Copyright 2018 Samsung Electronics France All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
 * either express or implied. See the License for the specific
 * language governing permissions and limitations under the License.
 *
 ****************************************************************************/
/****************************************************************************
 * examples/startup/startup_main.c
 *
 *   Copyright (C) 2008, 2011-2012 Gregory Nutt. All rights reserved.
 *   Author: Gregory Nutt <gnutt@nuttx.org>
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with the
 *    distribution.
 * 3. Neither the name NuttX nor the names of its contributors may be
 *    used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 * ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 ****************************************************************************/

#include <tinyara/config.h>
#include <stdio.h>
#include <wifi_manager/wifi_manager.h>

extern int iotjs(int argc, char *argv[]);

bool g_is_connected = false;

#ifndef CONFIG_EXAMPLES_STARTUP_JS_FILE
#define CONFIG_EXAMPLES_STARTUP_JS_FILE "/rom/example/index.js"
#endif


#ifdef CONFIG_EXAMPLES_STARTUP_WIFI

#ifndef CONFIG_EXAMPLES_STARTUP_WIFI_SSID
#define CONFIG_EXAMPLES_STARTUP_WIFI_SSID "public"
#endif

#ifndef CONFIG_EXAMPLES_STARTUP_WIFI_PASS
#define CONFIG_EXAMPLES_STARTUP_WIFI_PASS ""
#endif

void wifi_connect(void);


static void wifi_sta_connected(wifi_manager_result_e status) {
    printf("log: %s status=0x%x\n",__FUNCTION__, status);
    g_is_connected = true;
}

static void wifi_sta_disconnected(wifi_manager_disconnect_e status) {
    printf("log: %s status=0x%x\n",__FUNCTION__, status);
    g_is_connected = false;
    sleep(10);
    wifi_connect();
}

static wifi_manager_cb_s wifi_callbacks = {
    wifi_sta_connected,
    wifi_sta_disconnected,
    NULL,
    NULL,
    NULL,
};

void wifi_connect(void)
{
    printf("log: %s\n",__FUNCTION__);
    int i = 0;
    for(i = 0; i < 3; i++) {
        printf("log: Connecting to SSID \"%s\": Wait (%d/3) sec...\n",
               CONFIG_EXAMPLES_STARTUP_WIFI_SSID, i + 1);
        sleep(1);
    }

    wifi_manager_result_e status = WIFI_MANAGER_FAIL;
    wifi_manager_ap_config_s config;

    status = wifi_manager_init(&wifi_callbacks);
    if (status != WIFI_MANAGER_SUCCESS) {
        printf("error: manager: Failed to init (status=0x%x)", status);
    }
    config.ssid_length = strlen(CONFIG_EXAMPLES_STARTUP_WIFI_SSID);
    config.passphrase_length = strlen(CONFIG_EXAMPLES_STARTUP_WIFI_PASS);
    strncpy(config.ssid, CONFIG_EXAMPLES_STARTUP_WIFI_SSID, config.ssid_length + 1);
    strncpy(config.passphrase, CONFIG_EXAMPLES_STARTUP_WIFI_PASS, config.passphrase_length + 1);

#if 1 //Security: wpa2_aes
    int a = WIFI_MANAGER_AUTH_WPA2_PSK;
    int c = WIFI_MANAGER_CRYPTO_AES;
    config.ap_auth_type = (wifi_manager_ap_auth_type_e) a;
    config.ap_crypto_type = (wifi_manager_ap_crypto_type_e) c;
    status = wifi_manager_connect_ap(&config);
    if (status != WIFI_MANAGER_SUCCESS) {
        printf("error: manager: Failed to connect (status=0x%x)", status);
    }

#else //TODO: try
    int a;
    for (a = 0; a <= 5; a++) {  //TODO see headers wifi_manager_ap_auth_type_e
        int c;
        for (c = 0; c <= 6; c++)  { // TODO: wifi_manager_ap_crypto_type_e
            config.ap_auth_type = (wifi_manager_ap_auth_type_e) a;
            config.ap_crypto_type = (wifi_manager_ap_crypto_type_e) c;
            status = wifi_manager_connect_ap(&config);
            if (status != WIFI_MANAGER_SUCCESS) {
                printf("error: manager: Failed connect (status=0x%x)", status);
            }
        }
    }
#endif
}
#endif

#ifdef CONFIG_BUILD_KERNEL
int main(int argc, FAR char *argv[])
#else
    int startup_main(int argc, char *argv[])
#endif
{
    chdir("/rom/example"); //TODO
    char *targv[] = { "iotjs",
                      CONFIG_EXAMPLES_STARTUP_JS_FILE};
    int targc = 2;

#ifdef CONFIG_EXAMPLES_STARTUP_WIFI
    wifi_connect();
#else
    g_is_connected = true;
#endif
    for(;;) {
        if (g_is_connected) {
            iotjs(targc, targv);
        }
        sleep(10);
    }
    return 0;
}
