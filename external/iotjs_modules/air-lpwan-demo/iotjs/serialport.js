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

var EventEmitter = require('events').EventEmitter;
var uart = require('uart');

function log(arg) {
  if (true)
    return; // TODO: silent mode if !true
  try {
    console.log("log: serialport: " + JSON.stringify(arg));
  } catch (err) {
    console.log("log: serialport: err" + err);
    console.log("log: serialport: arg: " + arg);
  }
}

function die(err, message) {
  var text = "error: fatal: " + message;
  text += err.message; // if exeception
  log("die:");
  log(text);
  process.exit();
  return text;
}

function SerialPort(device, configuration) {
  configuration.device = device;
  var self = this;

  self.onError = function(err) { die(err, "onError"); }

  EventEmitter.call(self);
  self.uart = uart.open(configuration, function(err) {
    if (err) {
      self.emit("error", err);
    } else {
      self.uart.on('data', function(data) {
	self.emit("data", data);
      });
    }
  });

  return self;
}

SerialPort.prototype = Object.create(require('events').EventEmitter.prototype);

SerialPort.prototype.write = function write(message, callback) {
  var self = this;
  self.uart.write(message, callback);
}

module.exports = SerialPort;
