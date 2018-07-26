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
var index  = require('../index');
var Property = index.Property;
var SingleThing = index.server.SingleThing;
var Thing = index.Thing;
var Value = index.Value;
var WebThingServer = index.server.WebThingServer;
var fs = require('fs');
var Mastodon = require('mastodon-lite');
var conf = process.env.HOME + "/.mastodon-lite.json";
var config = JSON.parse(fs.readFileSync(conf, 'utf8'));
var mastodon = Mastodon(config);

function makeThing(context) {
  var thing = new Thing('MultiLevelSwitchExample', 'multiLevelSwitch', 'An actuator example that just blog');
  context.onPropertyOnValueChange = function(update) {
    console.log(update);
  };

  var value = new Value(0, function(update) {
    context.onPropertyOnValueChange(update);
  });

  thing.addProperty(
    new Property(thing,
                 'level',
                 value,
                 {type: 'number',
                  description: 'Whether the output is changed'}));
  return thing;
}

function runServer() {
  var port = Number(process.argv[2]) || 8888;
  var url = 'http://localhost:' + port;
  console.log('Usage:\n'
              + process.argv[0] + ' ' + process.argv[1] + ' [port]\n'
              + 'Try:\ncurl -H "Content-Type: application/json" '
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
  context.onPropertyOnValueChange = function(value) {
    if ( value ) {
      var message = value;
      message = "https://s-opensource.org/tag/iotjs/# #MultiLevelSwitch is \"" +  value + "\" (#WebThing powered by #MastodonLite #IoTjs and #MozillaIot)"
      console.log(message);
      mastodon.post(message);
    }
  }
  server.start();
}

runServer();
