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
var console = require('console');
var log = console.log || function(arg) {};
var gpio = require('gpio');
log(process);


function GpioTest(config)
{
  var self = this;
  if (!config) {
    config = { gpio: { pin: 0 , direction: gpio.DIRECTION.OUT }};
  }
  if (!gpio || !config || !(config.gpio)) {
    throw 'error: gpio: Invalid config: ' + gpio;
  }
  self.config = config;
  self.port = gpio.open(config.gpio, function(err) {
    log('log: gpio: ready: ' + err);
    if (err) {
      console.error('error: gpio: Fail to open pin: ' + config.gpio.pin);
      return null;
    }
    self.value = 0;
    self.inverval = setInterval(function() {
      self.value = !self.value;
      self.port.writeSync(self.value);
      log('log: gpio: update: ' + Boolean(self.value));
    }, self.config.period);
  });

  self.close = function() {
    try {
      self.inverval && clearInterval(self.inverval);
      self.port && self.port.closeSync();
    } catch(err) {
      console.error('error: gpio: close:' + err);
    }
  }
}

var gpio = require('gpio');
var pin = 0;
if (process.argv.length > 2) {
  pin = Number(process.argv[2]);
}
var config = { frequency: 1, gpio: { pin: pin , direction: gpio.DIRECTION.OUT }};
var test = new GpioTest(config);
