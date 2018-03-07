const express = require("express");
const session = require('express-session');

const app = express();
app.use(session({
  secret: 'super secret session'
}));

app.get('/', (req, res) => {
  res.send('Hello World!');
});

app.listen(3000, () => {
  console.log('Server listening on port 3000!');
});
