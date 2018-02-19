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
/**
 * Description:
 *
 * Plays Freesoftware song using PWM based on IoT's sample fur-elise
*
 * Usage:
 *
 * To run this sample please connect a low-power speaker, like a passive buzzer
 * (piezoelectric speaker), negative feed (-) to GND and positive feed (+) to
 * pin 3 on Artik055s CON703, and run the code by executing
 *
 *
 */

var pwm = require('pwm'),
  // note indexes definition
  // please remember that D# is same as Bb here
  notes = {
    "C": 0,
    "C#": 1,
    "D": 2,
    "D#": 3,
    "E": 4,
    "F": 5,
    "F#": 6,
    "G": 7,
    "G#": 8,
    "A": 9,
    "Bb": 10,
    "B": 11
  },
  // note frequencies
  frequencies = [
    //C, C#, D, Eb, E, F, F#, G, G#, A, Bb, B in ocatves from 0 to 8
    [16.35, 17.32, 18.35, 19.45, 20.60, 21.83, 23.12, 24.50, 25.96, 27.50,
      29.14, 30.87],
    [32.70, 34.65, 36.71, 38.89, 41.20, 43.65, 46.25, 49.00, 51.91, 55.00,
      58.27, 61.74],
    [65.41, 69.30, 73.42, 77.78, 82.41, 87.31, 92.50, 98.00, 103.8, 110.0,
      116.5, 123.5],
    [130.8, 138.6, 146.8, 155.6, 164.8, 174.6, 185.0, 196.0, 207.7, 220.0,
      233.1, 246.9],
    [261.6, 277.2, 293.7, 311.1, 329.6, 349.2, 370.0, 392.0, 415.3, 440.0,
      466.2, 493.9],
    [523.3, 554.4, 587.3, 622.3, 659.3, 698.5, 740.0, 784.0, 830.6, 880.0,
      932.3, 987.8],
    [1047, 1109, 1175, 1245, 1319, 1397, 1480, 1568, 1661, 1760, 1865, 1976],
    [2093, 2217, 2349, 2489, 2637, 2794, 2960, 3136, 3322, 3520, 3729, 3951],
    [4186, 4435, 4699, 4978, 5274, 5588, 5920, 6272, 6645, 7040, 7459, 7902]
  ],

  // https://www.gnu.org/music/free-software-song.en.html
  song = [
      ["D5", 0.2], ["C5", 0.1], ["B4", 0.2], ["A4", 0.2],
      ["B4", 0.2], ["C5", 0.1], ["B4", 0.1], ["A4", 0.1], ["G4", 0.2],
      ["G4", 0.3], ["A4", 0.3], ["B4", 0.1],
      ["C5", 0.3], ["B4", 0.2], ["B4", 0.1], ["D5", 0.1],
      ["A4", 0.3], ["A4", 0.4],
      ["D5", 0.2], ["C5", 0.1], ["B4", 0.4],
      ["D5", 0.2], ["C5", 0.1], ["B4", 0.2], ["A4", 0.2],
      ["B4", 0.2], ["C5", 0.1], ["B4", 0.1], ["A4", 0.1], ["G4", 0.2],
      ["G4", 0.3], ["A4", 0.3], ["B4", 0.1],
      ["C5", 0.3], ["B4", 0.2], ["B4", 0.1], ["D5", 0.1],
      ["A4", 0.3], ["A4", 0.4],
      ["A4", 0.7],
  ];


// log only when log_enable flag is set to true
function log(/*...args*/) {
var log_enable = false;
  if (log_enable) {
    console.log.apply(console, [].slice.call(arguments));
  }
}

function note2freq(noteStr) {
  var matches = noteStr.match(/([a-zA-Z\#]+)([0-9]+)/i),
    freq = 0;

  if (matches && matches.length === 3) {
    return frequencies[parseInt(matches[2], 10)][notes[matches[1]]];
  }

  return 0;
}


function AudioPwm() {
    var self = this;
    self.device = null;
    self.ready = true;
    return self;
}

// sets pwm period and runs callback after specified length of time
AudioPwm.prototype.setPeriod = function setPeriod(period, length, callback) {
var self = this;
  log('period: ' + period + ', length: ' + length + ' ms');
    self.device.setPeriod(period, function (err) {
    if (err) {
      callback(err);
    } else {
      setTimeout(callback, length);
    }
  });
}

// plays each note of song recursively and runs callback on end
AudioPwm.prototype.playSong = function playSong(song, callback, currentNote) {
  log("playSong");
  var self = this;
  var idx = currentNote === undefined ? 0 : currentNote,
    freq = 0;
  if (idx < song.length) {
    freq = note2freq(song[idx][0]);
    // period = 1 second / frequency
      self.setPeriod(freq !== 0 ? 1 / freq : 0.5, 1000 * song[idx][1],
                     function() {
                         self.playSong(song, callback, ++idx);
                     });
  } else {
    callback();
  }
}


AudioPwm.prototype.start = function start() {
    var self = this;
    if (! self.ready ) return false;
    self.ready = false;
    self.device = pwm.open({
  pin: 0,
  dutyCycle: 0.5,
  period: 1 / 10
}, function (err) {
  if (err) {
  } else {
      self.device.setEnableSync(true);
      self.playSong(song, function () {
        self.device.close(function (e) {
          self.ready = true;
      });
    });
  }
});
};

module.exports = AudioPwm;

// (new AudioPwm()).start(); //for testing
