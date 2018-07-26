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
var index  = require('webthing');
var Property = index.Property;
var SingleThing = index.server.SingleThing;
var Thing = index.Thing;
var Value = index.Value;
var WebThingServer = index.server.WebThingServer;
var gpio = require('gpio');

function makeThing(context) {
  var thing = new Thing('ActuatorExample', 
                        'onOffSwitch',
                        'An actuator example that just update GPIO');
  context.onPropertyOnValueChange = function(update) {
    console.log("change: " + update);
  };
  thing.addProperty(
    new Property(thing,
                 'on', 
                 new Value(true, function(update) {
                   context.onPropertyOnValueChange(update);
                 }),
                 {
                   '@type': 'OnOffProperty',
                   label: 'On/Off',
                   type: 'boolean',
                   description: 'Whether the output is changed'
                 }));
  return thing;
}

function runServer() {
  var port = process.argv[2] ? Number(process.argv[2]) : 8888;
  var pin = process.argv[3] ? Number(process.argv[3]) : 45;
  var url = 'http://localhost:' + port + '/properties/on';

  console.log('Usage:\n'
              + process.argv[0] + ' ' + process.argv[1] + ' [port] [gpio]\n'
              + 'Try:\ncurl -X PUT -H "Content-Type: application/json" --data \'{"on": true }\' '
              + url + '\n');

  var context = {
    onPropertyOnValueChange: null,
  };
  var thing = makeThing(context);
  var server = new WebThingServer(new SingleThing(thing), port);
  process.on('SIGINT', function(){
    server.stop();
    process.exit();
  });
  var gpio_out = gpio.open({
    pin: pin,
    direction: gpio.DIRECTION.OUT
  }, function(err) {
    if (err) {
      console.log("error: gpio: Can't be opened on pin " + pin);
      return err;
    }
    context.onPropertyOnValueChange = function(value) {
      try {
        console.log("gpio: writing: " + value);
        gpio_out.write(value);
      } catch(err) {
        console.log("error: gpio: "  + pin);
      }
    }
    server.start();
  });
}

runServer();
