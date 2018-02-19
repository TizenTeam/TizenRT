// -*- mode: js; js-indent-level:2; -*-
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

//'use strict'; //TODO

var adc = require('adc');
var EventEmitter = require('events').EventEmitter;

/**
 * Class inspired by W3C's generic-sensor + oneiota:
 * (start, onreading, onerror...)
 * @related: https://www.w3.org/TR/generic-sensor/
 * @related: https://www.oneiota.org/revisions/2422#  oic.r.airquality.json
 **/
function AirQuality(configuration) {
  var self = this;
  EventEmitter.call(self);
  if (null === configuration) {
    configuration = {frequency : 1, adc : {device : '/dev/adc0', pin : 0}};
  }
  self.config = configuration;
  self.frequency = configuration.frequency;
  self.interval = null;
  self.contaminantvalue = 0;
  self.contaminanttype = "AirPollution";
  self.valuetype = "Measured";
  self.unhealthy = 100; // TODO: Calibrate
  return self;
}

AirQuality.prototype = Object.create(require('events').EventEmitter.prototype);

AirQuality.prototype.update = function update() {
  var self = this;
  if (false)
    console.log("update" + self.contaminantvalue);
  try {
    self.port.read(function(err, value) {
      if (err) {
        return self.emit("onerror", err);
      } else {
        self.contaminantvalue = value;
        self.emit("onreading", self.contaminantvalue);
      }
    });
  } catch (e) {
    return self.emit("onerror", e);
  }
}

AirQuality.prototype.stop = function stop() {
  var self = this;
  try {
    clearInterval(self.interval);
    self.interval = null;
    self.port.close();
  } catch (e) {
    return self.emit("onerror", e);
  }
}

AirQuality.prototype.start = function start() {
  var self = this;
  self.port = adc.open(self.config.adc, function(err) {
    if (err) {
      return self.emit("onerror", self);
    }
    if (null === self.interval) {
      self.interval = setInterval(function() { self.update(); },
                                  1000. / self.frequency);
    }
  });
}

module.exports = AirQuality;
