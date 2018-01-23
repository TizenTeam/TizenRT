// -*- mode: js; js-indent-level:2;  -*-
var request = require('request');

function main() {
  var username = "TizenHelper";
  var password = username;
  var message = "https://quitter.is/group/tizen";
  var url = "https://quitter.is/api/statuses/update.xml";

  if (process.argv.length > 1) {
    message = process.argv[2];
  }

  var request = require('request');

  console.log(message);

  request
      .post({url : url, form : {"status" : message}},
            function(error, response, body) {
              console.log(response);
              if (!error && response.statusCode == 200) {
                console.log(body)
              }
            })
      .auth(username, password, false);
}

// console.log( main);
module.exports = main;

if (process.argv.length > 1) {
  main();
}
