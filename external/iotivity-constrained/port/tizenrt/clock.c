/*
// Copyright (c) 2018 Samsung Electronics France SAS
// Copyright (c) 2016 Intel Corporation
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
*/

#include "port/oc_clock.h"
#include "port/oc_assert.h"
#include <math.h>
#include <time.h>
#include <unistd.h>

void
oc_clock_init(void)
{
        LOG();
}

oc_clock_time_t
oc_clock_time(void)
{
  oc_clock_time_t time = 0;
  struct timespec t;
          LOG();
  if (clock_gettime(CLOCK_REALTIME, &t) != -1) {
    time = (oc_clock_time_t)t.tv_sec * OC_CLOCK_SECOND +
           (oc_clock_time_t)ceil(t.tv_nsec / (1.e09 / OC_CLOCK_SECOND));
  }
  return time;
}

unsigned long
oc_clock_seconds(void)
{
  struct timespec t;
          LOG();
  if (clock_gettime(CLOCK_REALTIME, &t) != -1) {
    return t.tv_sec;
  }
  return 0;
}

void
oc_clock_wait(oc_clock_time_t t)
{
        LOG();
  usleep(t * 1.e03);
}

