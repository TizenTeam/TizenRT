/****************************************************************************
 *
 * Copyright 2017 Samsung France All Rights Reserved.
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

#include <tinyara/config.h>

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>


#ifdef CONFIG_BUILD_KERNEL
int main(int argc, FAR char *argv[])
#else
int version_main(int argc, char *argv[])
#endif
{
    /// TODO: this is breaking reproductible build
    printf("log: " __FILE__
           "\nlog:" __DATE__ " " __TIME__  "\n");
#if 1
    char* filename = "/proc/version";
    if (1 < argc) {
        filename = argv[1];
    }
    FILE* f = fopen(filename, "r"); // TODO: "rt" failure=22
    if (NULL == f) {
        printf("log: error: io: Failed to open file: %d \n", errno);
        exit (errno);
    }
    char line[1024];
    int len = fread(line,1,sizeof(line),f);
    line[len] = 0;
    fclose(f);
    printf("log: read=%d/%d\n", len, sizeof(line));
    for(;;) {
        //printf("%s", line);
        puts(line);
        sleep(5);
    }
#endif
    return 0;
}
