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


console.log('log: IoT.js app: Starting:');
console.log(process);
var main = '/rom/iotjs-modules/webthing-iotjs/example/platform/index.js';
console.log('log: IoT.js app: Loading: ' + main);
var app = require(main);