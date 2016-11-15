'use strict';
var co = require('co');
var webdriver = require('pocci/webdriver.js');

co(function*() {
  yield webdriver.init();
  yield webdriver.browser
    .url('http://user:9898/')
    .setValue("#login-cn", "admin")
    .setValue("#login-userPassword", "admin")
    .save("user-admin-berore-autherize")
    .click("#login button")
    .save("user-admin-after-autherize");
  process.exit(0);
}).catch(function(err) {
  console.error(err);
  process.exit(1);
});
