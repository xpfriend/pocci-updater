'use strict';
var server = require('co-request');
var co = require('co');
var images = require('./version.json')

var getVersion = function(s) {
    var version = [0, 0, 0, 0, 0, 0, 0, 0];
    var index = 0;
    for(var i = 0; i < s.length && index < version.length; i++) {
        if(s[i].match(/[0-9]/)) {
            version[index] = (version[index]*10) + parseInt(s[i]);
        } else if(index > 0 || version[index] > 0) {
            if(s[i] === '-') {
                index++;
            } else if(index%2 === 0) {
                index += 2;
            } else {
                index++;
            }
        }
    }
    return version;
};

var getMaxVersion = function(aStr, bStr) {
    var a = getVersion(aStr);
    var b = getVersion(bStr);
    for(var i = 0; i < a.length; i++) {
        if(a[i] > b[i]) {
            return aStr;
        } else if(a[i] < b[i]) {
            return bStr;
        }
    }
    return aStr;
};

var findLatestFrom = function*(imageName) {
  var image = imageName.split(':');
  var res = yield server.get({
    url: `https://registry.hub.docker.com/v2/repositories/${image[0]}/dockerfile/`,
    json: true
  });
  var contents = res.body.contents.split('\n');
  for(var i = 0; i < contents.length; i++) {
    if(contents[i].startsWith('FROM ')) {
      return yield findLatest(contents[i].split(' ')[1]);
    }
  }
  return null;
};

var findLatest = function*(imageName) {
  var image = imageName.split(':');
  if(image[1] === 'latest') {
    return null;
  }
  var name = image[0];
  if(name.indexOf('/') == -1) {
    name = 'library/' + name;
  }

  var next = `https://registry.hub.docker.com/v2/repositories/${name}/tags/`;
  var results = [];
  while(next) {
    var res = yield server.get({
      url: next,
      json: true
    });
    var body = res.body;
    results = results.concat(body.results);
    next = body.next;
  }
  var tag = '';
  for(var i = 0; i < results.length; i++) {
    var result = results[i];
    if(result.name !== 'latest' && 
        (result.name.indexOf('beta') == -1) &&
        (name !== 'library/python' || (result.name.startsWith('3.5') && result.name.endsWith('-alpine'))) &&
        (name !== 'library/java' || (result.name.startsWith('openjdk-8u') && result.name.endsWith('-jdk'))) &&
        (name !== 'library/nginx' || result.name.endsWith('-alpine')) &&
        (name !== 'gitlab/gitlab-runner' || result.name.startsWith('alpine-')) &&
        (name !== 'library/jenkins' || result.name.endsWith('-alpine'))) {
      tag = getMaxVersion(tag, result.name);
    }
  }

  var latest = `${name}:${tag}`;
  if(latest !== `${name}:${image[1]}`) {
    return latest;
  } else {
    return null;
  }
};

co(function*() {
  var from = process.argv.length > 2 && process.argv[2] === "from";
  for(var i = 0; i < images.length; i++) {
    var latest;
    if(from) {
      latest = yield findLatestFrom(images[i]);
    } else {
      latest = yield findLatest(images[i]);
    }
    if(latest) {
      console.log(`${images[i]} --> ${latest}`);
    }
  }
}).catch(function(err) {
  console.error(err);
});

