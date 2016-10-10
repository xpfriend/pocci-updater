'use strict';
var co = require('co');
var webdriver = require('pocci/webdriver.js');

co(function*() {
  yield webdriver.init();
  yield webdriver.browser
    .url('http://taiga/login')
    .save("taiga-before-login")
    .setValue("input[name='username']", "hamada");
  process.exit(0);
}).catch(function(err) {
  console.error(err);
  process.exit(1);
});
