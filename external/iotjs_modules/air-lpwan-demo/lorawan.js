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

var EventEmitter = require('events').EventEmitter;

var runtime = 'iotjs';
if (undefined !== process.argv[0]) {
  runtime = process.argv[0];
}

var serialport = (runtime === "iotjs") ? runtime + '/' + 'serialport' : 'serialport';
var SerialPort = require(serialport);

function log(arg) {
  if (false)
    return; // TODO: silent mode if !false
  try {
    console.log("log: lorawan: " + JSON.stringify(arg));
  } catch (err) {
    console.log("log: lorawan: arg: " + arg);
    console.log("log: lorawan: err" + err);
  }
}

function LoraWan(configuration) {
  var self = this;
  EventEmitter.call(self);
  if (null === configuration) {
    configuration = {
      method : "abp",
      nwkskey : "2B7E151628AED2A6ABF7158809CF4F3C", // TODO: (demo settings)
      appskey : "2B7E151628AED2A6ABF7158809CF4F3C", // TODO: TheThingNetwork
      devaddr : "1B4DC0DE",
      serialport : {device : '/dev/ttyS1', config : {baudrate : 57600}}
    }
  }
  self.config = configuration;
  self.state = "init";
  self.queue = [];
  self.eol = "\r\n"; // for RN2483
  self.tick = 2 * 1000;
  self.delay = 1000 * 60 * 60 / 30; // TODO: fair use is 1 per hour
  self.portno = 1;                  // for sending
  return self;
}

LoraWan.prototype = Object.create(require('events').EventEmitter.prototype);

// TODO, add expected answer and timeout for resend
LoraWan.prototype.tx = function tx(message) {
  var self = this;
  // log("#{ tx: " + message);
  message = message + self.eol;
  self.queue.push(message);
  // log("#} tx: " + self.queue.length);
}

LoraWan.prototype.send = function send(value) {
  var self = this;
  log("send: May be skipped if no bandwidth :" + self.state);
  //self.tx("mac resume");
  self.tx("mac tx uncnf " + self.portno + " " +value); // expect: "ok", "mac_tx_ok"
}

LoraWan.prototype.status = function status() {
  var self = this;
  log("status: " + self.state);
  self.tx("mac get status");
}

LoraWan.prototype.join = function join() {
  var self = this;

  self.tx("mac get devaddr"); // expect: 26ffFFff
  self.tx("mac join " +  self.config.method); // expect: ok, accepted (after 5secs)
  self.tx("radio get mod");   // expect: lora
  self.tx("radio get freq");  // expect: 868500000
  self.tx("radio get pwr");   // expect: 14
  self.tx("radio get sf");      // expect: sf12
  self.tx("radio set sf sf12");      // expect: ok
  self.tx("radio get sf");      // expect: sf12
  self.tx("mac get band");    // expect: 868
  self.tx("mac get dr");      // expect: 0
  self.tx("mac get gwnb");    // expect: 0
  self.tx("mac get upctr");   // expect: 0
  self.tx("mac get dnctr");   // expect: 0
  self.tx("mac get devaddr"); // expect: 26ffFFff
}

LoraWan.prototype.start = function start() {
  var self = this;
  self.port = new SerialPort(self.config.serialport.device,
                             self.config.serialport.config);
  self.port.on('error', function(err) {
    if (err)
      return self.emit("onerror", self);
  });

  self.port.on('data', function(data) {
    if (true) {
      log('< rx: "' + data.toString() + '"');
      // self.emit("ondata", data); ///TODO: emit upper level
    }
    if (data.indexOf("ok") >= 0) {
      if (self.state == "init")
        self.state = "ready";
    } else if (data.indexOf("denied") >= 0 || data.indexOf("not_joined") >= 0) {
      self.state = "not_joined";
      setTimeout(function() { self.join() }, 5000);
    } else if (data.indexOf("accepted") >= 0) {
      self.state = "accepted";
    } else if (data.indexOf("busy") >= 0) {
    } else if (data.indexOf("no_free_ch") >= 0) {
      self.state = 'wait';
      self.timeout = setTimeout(function() { self.state = "accepted"; }, self.delay);
    }
  });

  self.tx("sys get ver");   // flush with eol
  self.tx("sys reset");     // flush with eol
  self.tx("sys get ver");   // expect: "RN2483 1.0.3 Mar 22 2017"
  self.tx("sys get hweui"); // expect: 00FFffFFffFFffFF

  if (true) { // TODO: only set once to speed up
    if ("abp" === self.config.method) {
      self.tx("mac set nwkskey " + self.config.nwkskey); // expect: ok
      self.tx("mac set appskey " + self.config.appskey); // expect: ok
      self.tx("mac set devaddr " + self.config.devaddr); // expect: ok

    } else if ("otaa" === self.config.method) {
      self.tx("mac set appeui " + self.config.appeui); // expect: ok
      self.tx("mac set appkey " + self.config.appkey); // expect: ok
    }
    self.tx("mac save"); // optionnal
  }
  self.join();

  self.interval = setInterval(function() {
    log("tick: " + self.state + " [" + self.queue.length + "]");
    var message = "mac get status";
    if (self.queue.length <= 0) {
      // message = "sys sleep " + (self.tick / 2); //TODO: optimize here
      self.tx(message);
      return;
    } else {
      message = self.queue.shift();
    }
    if (self.state === "wait") {
      if (message.indexOf("mac tx") >= 0) {
        log("wait: skip: " + message);
        return;
      }
    }
    self.port.write(message, function(err) {
      if (err) {
        log("error: " + err);
        return self.emit("onerror", self);
      }
      log("> tx: " + message);
      if (message.indexOf("mac tx") >= 0) {
        self.state = "wait";
        self.timeout = setTimeout(function() { self.state = "accepted"; }, self.delay);
      } else if (message.indexOf("join") >= 0) {
        setTimeout(function() {
          log("expect: accepted after 5secs? " + self.state);
        }, 6000);
      }
    });
  }, self.tick);
}

LoraWan.prototype.stop = function stop() {
  self = this;
  self.state = "stop";
  if (null !== self.interval) {
    clearInterval(self.interval);
    self.interval = null;
  }
}

module.exports = LoraWan;
