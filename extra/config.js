// -*- mode: js; js-indent-level:2;  -*-
/* Copyright 2018-present Samsung Electronics Co., Ltd. and other contributors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

module.exports = {
  runtime: 'iotjs',
  airquality: { 
    frequency: 2, // in Hz , 2 per sec is good value
    adc: {device: '/dev/adc0' , pin: 0}
  },
  lorawan: {
    method: "adp",
    nwkskey: "2B7E151628AED2A6ABF7158809CF4F3C", //TODO: update
    appskey: "2B7E151628AED2A6ABF7158809CF4F3C", //TODO: update
    devaddr: "2BADC0DE", //TODO: update
    serialport: { device: '/dev/ttyS1', config: { baudrate: 57600 } }
  }
};
