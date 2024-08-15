#!/bin/bash

# Create directories if they do not exist
mkdir -p src/components
mkdir -p src/utils
mkdir -p netlify/functions

# Create Vue component
cat <<EOL > src/components/VueComponent.vue
<template>
  <div>
    <button @click="redirectToOracleLogin">Login with Oracle</button>
    <input type="file" @change="handleFileUpload" multiple>
    <input type="text" v-model="ossUrl" placeholder="Enter OSS URL">
    <button @click="fetchAndUploadFromUrl">Upload from OSS URL</button>
    <button @click="compressAndUploadFiles">Upload to OCI</button>
  </div>
</template>

<script>
import axios from 'axios';

export default {
  data() {
    return {
      files: [],
      ossUrl: '',
      accessToken: null
    };
  },
  methods: {
    redirectToOracleLogin() {
      const clientId = process.env.VUE_APP_CLIENT_ID;
      const redirectUri = process.env.VUE_APP_REDIRECT_URI;
      const ociLoginUrl = \`https://login.ap-sydney-1.oraclecloud.com/v2/ui/domains?client_id=\${clientId}&redirect_uri=\${encodeURIComponent(redirectUri)}&response_type=code&scope=\`;
      window.location.href ociLoginUrl;
    },
    handleFileUpload(event) {
      this.files = Array.from(event.target.files);
    },
    async fetchAndUploadFromUrl() {
      try {
        const response = await axios.get(this.ossUrl, { responseType: 'blob' });
        const file = new File([response.data], 'oss-file');
        this.files.push(file);
        await this.compressAndUploadFiles();
      } catch (error) {
        console.error('Error fetching file from OSS URL:', error.response ? error.response.data : error.message);
      }
    },
    async compressAndUploadFiles() {
      try {
        const compressedFilePath = await this.compressFiles(this.files, 'output.tar.gz');
        const response = await this.uploadToOCI('your-bucket-name', 'output.tar.gz', compressedFilePath, this.accessToken);
        console.log('Upload successful:', response);
      } catch (error) {
        console.error('Error uploading files:', error.response ? error.response.data : error.message);
      }
    },
    compressFiles(files, outputFilePath) {
      // Implement file compression logic here
    },
    uploadToOCI(bucketName, objectName, filePath, accessToken) {
      // Implement file upload logic here
    }
  },
  async mounted() {
    try {
      const urlParams = new URLSearchParams(window.location.search);
      const authorizationCode = urlParams.get('code');

      if (authorizationCode) {
        const tokenResponse = await axios.get(\`/.netlify/functions/oauth2-callback?code=\${authorizationCode}\`);
        this.accessToken = tokenResponse.data.access_token;
      }
    } catch (error) {
      console.error('Error during OAuth callback:', error.response ? error.response.data : error.message);
    }
  }
};
</script>
EOL

# Create Netlify function for OAuth2 callback
cat <<EOL > netlify/functions/oauth2-callback.js
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
EOL

# Create Netlify configuration file
cat <<EOL > netlify.toml
[build]
  functions = "netlify/functions"

[[redirects]]
  from = "/oauth2/callback"
  to = "/.netlify/functions/oauth2-callback"
  status = 200
EOL

# Install necessary npm packages
npm install express axios querystring gh-pages

# Install jq
sudo apt-get install -y jq

# Add deploy scripts to package.json using sed
sed -i '/"scripts": {/a \    "predeploy": "npm run build",\n    "deploy": "gh-pages -d dist",' package.json

# Fix vulnerabilities
npm audit fix

# Deploy the Vue application to GitHub Pages
npm run deploy

echo "Setup complete. Don't forget to set the environment variables CLIENT_ID, CLIENT_SECRET, and REDIRECT_URI in your Netlify dashboard."

# Authenticate with GitHub CLI
gh auth login

# Create the repository on GitHub
gh repo create ngs-uploader --public --source=. --remote=origin

# Add and commit changes
git add .
git commit -m "Initial commit"

# Push changes to GitHub
git push origin master