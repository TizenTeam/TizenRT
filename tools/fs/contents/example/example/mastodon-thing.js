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
var fs = require('fs');
var Mastodon = require('mastodon-lite');
var conf = "/rom/webthing-node/" + ".mastodon-lite.json";
var config = JSON.parse(fs.readFileSync(conf, 'utf8'));
var mastodon = Mastodon(config);

function handleLevelUpdate(value)
{ 
  var message = "https://s-opensource.org/tag/wot/# #MultiLevelSwitch is \"" + value + "\" (#MastodonLite #WebThing Actuator)";
  console.log(message);
  mastodon.post(message);
}

function makeThing() {
  var thing = new Thing('MastodonMultiLevelSwitchExample', 'multiLevelSwitch', 'An actuator example that just blog');

  thing.addProperty(
    new Property(thing,
                 'level',
                 new Value(0, function(value) { handleLevelUpdate(value); }),
                 {
                   label: 'Level',
                   type: 'number',
                   description: 'Whether the output is changed'
                 }));
  return thing;
}

function runServer() {
  var port = Number(process.argv[2]) || 8888;
  var url = 'http://localhost:' + port;
  console.log('Usage:\n'
              + process.argv[0] + ' ' + process.argv[1] + ' [port]\n'
              + 'Try:\ncurl -H "Content-Type: application/json" '
              + url + '\n');

  var thing = makeThing();
  var server = new WebThingServer(new SingleThing(thing), port);
  process.on('SIGINT', function(){
    server.stop();
    process.exit();
  });
  server.start();
}

runServer();
