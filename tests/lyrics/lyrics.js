const _ = require("underscore");

var lyrics = [
  'I\'m a lumberjack and I\'m okay',
  'I sleep all night and I work all day',
  'He\'s a lumberjack and he\'s okay',
  'He sleeps all night and he works all day'
];

var counts = _(lyrics).chain()
      .map(line => line.split(''))
      .flatten()
      .reduce((hash, l) => {
        hash[l] = hash[l] || 0;
        hash[l]++;
        return hash;
      }, {})
      .value();

console.log(`Count (letter a): ${counts.a}`);
