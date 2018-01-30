// -*- mode: js; js-indent-level:2;  -*-
/* Copyright 2017-present Samsung Electronics Co., Ltd. and other contributors
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

var http = require('https');

function receive(incoming, callback) {
  var data = '';

  incoming.on('data', function(chunk) { data += chunk; });

  incoming.on('end', function() { callback ? callback(data) : ''; });
}

module.exports.send = function send(message, config) {
  if (undefined === message) {
    message = 'ping from #IoTJs to @TizenHelper@quitter.is';
    console.log("log: TODO: must provide message, attempt to use default: " + message);
  }

  if (undefined === config) {
    var config = {
      hostname : 'localhost',
      port : 443,
      path : '/api/statuses/update.xml',
      method : 'POST',
      auth : 'user:password' //TODO: update here
    };
    console.log("log: TODO: must provide config, attempt to use defaults: " + config);
  }
  message = 'status="' + message + '"';
  config.headers = { 'Content-Length': message.length };
  http.request(config, function(res) {
    receive(res, function(data) {
      console.log(data);
    });
  }).end(message);
}

if (process.argv.length > 1) {
  var message = "https://wiki.tizen.org/Special:RecentChanges# Check Tizen's wiki latest changes";
  var config = {
    hostname : 'quitter.is',
    port : 443,
    path : '/api/statuses/update.xml',
    method : 'POST',
    auth : 'user:password' //TODO: update here
  };
  exports.send(message, config);
}
