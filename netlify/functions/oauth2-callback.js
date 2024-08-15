const axios = require('axios');
const querystring = require('querystring');

exports.handler = async (event, context) => {
  const clientId = process.env.CLIENT_ID;
  const clientSecret = process.env.CLIENT_SECRET;
  const redirectUri = process.env.REDIRECT_URI;
  const tokenEndpoint = 'https://login.ap-sydney-1.oraclecloud.com/oauth2/v1/token';

  const authorizationCode = event.queryStringParameters.code;

  try {
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
    return {
      statusCode: 200,
      body: JSON.stringify(tokens)
    };
  } catch (error) {
    return {
      statusCode: error.response.status,
      body: JSON.stringify(error.response.data)
    };
  }
};
