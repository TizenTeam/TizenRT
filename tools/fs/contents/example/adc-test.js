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
log(process);

var adc = require('adc');

function AdcTest(config)
{
  var self = this;
  if (!config) {
    config = { frequency: 1, adc: { device: '/dev/adc0', pin: 0}};
  }
  if (!adc || !config || !(config.adc)) {
    throw 'error: adc: Invalid config: ' + adc;
  }
  config.frequency = config.frequency || 1;
  config.range = config.range || 0xfff;
  config.period = config.frequency && (1000. / config.frequency );
  self.config = config;
  self.port = adc.open(config.adc, function(err) {
    log('log: adc: ready: ' + err);
    if (err) {
      console.error('error: adc: Fail to open pin: ' + config.adc.pin);
      return null;
    }
    self.inverval = setInterval(function() {
      var value = self.port.readSync();
      log('log: adc: update: ' + Number(value));
      log('log: adc: update: 0x' + Number(value).toString(16));
      log('log: adc: update: 0b' + Number(value).toString(2));
      value = Math.floor(100. * value / self.config.range);
      log('log: adc: update: ' + value + '%');

    }, self.config.period);
  });

  self.close = function() {
    try {
      self.inverval && clearInterval(self.inverval);
      self.port && self.port.closeSync();
    } catch(err) {
      console.error('error: adc: close:' + err);
    }
  }
}

var test = new AdcTest();
