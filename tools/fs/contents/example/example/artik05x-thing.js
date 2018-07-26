// -*- mode: js; js-indent-level:2;  -*-
// SPDX-License-Identifier: MPL-2.0
/**
 *
 * Copyright 2018-present Samsung Electronics France SAS, and other contributors
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.*
 */
var index = require('webthing');
var Property = index.Property;
var MultipleThings= index.server.MultipleThings;
var Thing = index.Thing;
var Value = index.Value;
var WebThingServer = index.server.WebThingServer;

var gpio = require('gpio');

/// TODO: disable logs here by editing to '!console.log'
var log = console.log || function(arg) {};

function GpioOnOffSwitch(pin, name, description) {
  Thing.call(this, name,'onOffSwitch',
             description || "A web connected actuator");
  var self = this;
  {
    this.pin = pin;
    this.onValueChange = null;
    this.value = new Value(false, function(value) {
      log("log: " + self.getName() + " update: " + value);
      if (typeof self.onValueChange == 'function')
        self.onValueChange(value);
    });
    this.addProperty(
      new Property(this,
                   'on',
                   this.value,
                   {
                     '@type': 'OnOffProperty',
                     label: 'On/Off',
                     type: 'boolean',
                     description: 'Whether the output is changed',
                   }));

    this.output = gpio.open({
      pin: this.pin,
      direction: gpio.DIRECTION.OUT
    }, function(err) {
      log("log: " + self.getName() + " ready: " + err);
      if (err) {
        console.log("error: " + self.getName() + "gpio: Fail to open pin: " + this.pin);
        return err;
      }
      self.onValueChange = function(value) {
        try {
          log("log: " + self.getName() + " writing: " + value);
          self.output.write(value);
        } catch(err) {
          console.log("error: gpio: "  + pin);
        }
      };
    });
  }
  this.close = function() {
    try {
      self.input.closeSync();
    } catch(err) {
      console.log("error: " + self.getName() + " close:" + err);
    }
  }
}

function GpioBinarySensor(pin, name, description) {
  Thing.call(this, name, 'binarySensor',
             description || "A web connected sensor");
  var self = this;
  {
    this.pin = pin;
    this.period = 500; //TODO, 1000 is working , 42 is not faster, polling about 5sec
    this.value = new Value(true,
                           function(value) {
                             log("log: " + self.getName() + " update: " + value);
                           });
    this.addProperty(
      new Property(this,
                   'on',
                   this.value,
                   {
                     '@type': 'OnOffProperty',
                     label: 'On/Off',
                     type: 'boolean',
                     description: 'Whether the input is changed',
                   }));
    this.input = gpio.open({
      pin: this.pin,
      direction: gpio.DIRECTION.IN
    }, function(err) {
      if (err) {
        console.log("error: " + self.getName() + "gpio: Fail to open pin: " + this.pin);
        return null;
      }
      log("log: " + self.getName() + " ready:" + err);
      self.inverval = setInterval(function() {
        var value = self.input.readSync();
        log("log: " + self.getName() + " gpio: update: "  + value);
        if ( value != self.lastValue ) {
          self.value.notifyOfExternalUpdate(Boolean(value));
        }
        self.lastValue = value;

      }, self.period);
    });
  }
  this.close = function() {
    try {
      self.inverval && clearInterval(self.inverval);
      self.input.closeSync();
    } catch(err) {
      console.log("error: " + self.getName() + " close:" + err);
    }
  }
}

function runServer() {
  var port = process.argv[2] ? Number(process.argv[2]) : 80;
  var url = "http://localhost:" + port;

  console.log('Usage:\n'
              + process.argv[0] + ' ' + process.argv[1] + ' [port]\n'
              + 'Try:\ncurl -H "Accept: application/json" '
              + url + '\n');

  var things = [
    new GpioOnOffSwitch(45, "Artik05xRedLed", "Red LED on ARTIK05x board (GPIO45)"),
    new GpioOnOffSwitch(49, "Artik05xBlueLed", "Blue LED on ARTIK05x board (GPIO49)"),
    new GpioBinarySensor(42, "Artik05xLeftButton", "Left Button on ARTIK05x board (GPIO42)"),
    new GpioBinarySensor(44, "Artik05xRightButton", "Right Button on ARTIK05x board (GPIO44)"),
  ];
  var server = new WebThingServer(new MultipleThings(things,
                                                     "Artik05xDevice"),
                                  port);
  process.on('SIGINT', function() {
    server.stop();
    for (var thing in things) {
      thing=things[thing];
      thing && thing.close();
    }
    process.exit();
  });

  server.start();
}

runServer();
