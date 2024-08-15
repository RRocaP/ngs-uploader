const express = require('express');
const axios = require('axios');
const querystring = require('querystring');

const app = express();
const port = 3000;

const clientId = 'your_actual_client_id';
const clientSecret = 'your_actual_client_secret';
const redirectUri = 'your_actual_redirect_uri';
const tokenEndpoint = 'https://login.ap-sydney-1.oraclecloud.com/oauth2/v1/token';

app.get('/oauth2/callback', async (req, res) => {
  const authorizationCode = req.query.code;

  const tokenResponse = await axios.post(tokenEndpoint, querystring.stringify({
    grant_type: 'authorization_code',
    code: authorizationCode,
    redirect_uri: redirectUri,
    client_id: clientId,
    client_secret: clientSecret
  }), {
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded'
    }
  });

  const tokens = tokenResponse.data;
  res.json(tokens); // Send tokens back to the frontend
});

app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});
