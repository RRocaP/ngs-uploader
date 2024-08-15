#!/bin/bash

# Create directories
mkdir - p src / components
mkdir - p src / utils
mkdir - p backend

# Create Vue component
cat << EOL > src / components / VueComponent.vue
    < template >
    <div>
    <button @click="redirectToOracleLogin" > Login with Oracle </button>
    < input type = "file" @change="handleFileUpload" multiple >
        <input type="text" v - model="ossUrl" placeholder = "Enter OSS URL" >
            <button @click="fetchAndUploadFromUrl" > Upload from OSS URL </button>
                < button @click="compressAndUploadFiles" > Upload to OCI </button>
                    </div>
                    </template>

                    <script>
import axios from 'axios';
import { compressFiles, uploadToOCI } from '../utils/oci-utils'; // Import your utility functions

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
            const clientId = 'YOUR_CLIENT_ID';
            const redirectUri = 'YOUR_REDIRECT_URI';
            const ociLoginUrl = \`https://login.ap-sydney-1.oraclecloud.com/v2/ui/domains?client_id=\${clientId}&redirect_uri=\${encodeURIComponent(redirectUri)}&response_type=code&scope=\`;
      window.location.href = ociLoginUrl;
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
        const compressedFilePath = await compressFiles(this.files, 'output.tar.gz');
        const response = await uploadToOCI('your-bucket-name', 'output.tar.gz', compressedFilePath, this.accessToken);
        console.log('Upload successful:', response);
      } catch (error) {
        console.error('Error uploading files:', error.response ? error.response.data : error.message);
      }
    }
  },
  async mounted() {
    try {
      const urlParams = new URLSearchParams(window.location.search);
      const authorizationCode = urlParams.get('code');

      if (authorizationCode) {
        const tokenResponse = await axios.get(\`/oauth2/callback?code=\${authorizationCode}\`);
        this.accessToken = tokenResponse.data.access_token;
      }
    } catch (error) {
      console.error('Error during OAuth callback:', error.response ? error.response.data : error.message);
    }
  }
};
</script>
EOL

# Create utility functions
cat <<EOL > src/utils/oci-utils.js
const archiver = require('archiver');
const fs = require('fs');
const path = require('path');
const oci = require('oci-sdk');
const config = require('../../backend/oci-config');

async function compressFiles(files, outputFilePath) {
  return new Promise((resolve, reject) => {
    const output = fs.createWriteStream(outputFilePath);
    const archive = archiver('tar', {
      gzip: true,
      gzipOptions: {
        level: 1
      }
    });

    output.on('close', () => resolve(outputFilePath));
    archive.on('error', (err) => reject(err));

    archive.pipe(output);

    files.forEach(file => {
      archive.file(file.path, { name: path.basename(file.path) });
    });

    archive.finalize();
  });
}

async function uploadToOCI(bucketName, objectName, filePath, accessToken) {
  const objectStorageClient = new oci.ObjectStorageClient({
    authenticationDetailsProvider: new oci.SimpleAuthenticationDetailsProvider({
      accessToken: accessToken
    })
  });

  const namespace = await objectStorageClient.getNamespace({});
  const uploadDetails = {
    namespaceName: namespace.value,
    bucketName: bucketName,
    objectName: objectName,
    putObjectBody: fs.createReadStream(filePath)
  };

  const response = await objectStorageClient.putObject(uploadDetails);
  return response;
}

module.exports = {
  compressFiles,
  uploadToOCI
};
EOL

# Create backend server
cat <<EOL > backend/server.js
const express = require('express');
const axios = require('axios');
const querystring = require('querystring');

const app = express();
const port = 3000;

const clientId = 'YOUR_CLIENT_ID';
const clientSecret = 'YOUR_CLIENT_SECRET';
const redirectUri = 'YOUR_REDIRECT_URI';
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
  console.log(\`Server running at http://localhost:\${port}\`);
});
EOL

# Create OCI configuration
cat <<EOL > backend/oci-config.js
module.exports = {
  user: 'YOUR_USER_OCID',
  tenancy: 'YOUR_TENANCY_OCID',
  region: 'YOUR_REGION',
  fingerprint: 'YOUR_PUBLIC_KEY_FINGERPRINT',
  privateKeyPath: 'path/to/your/private_key.pem'
};
EOL

echo "Setup complete. Please replace placeholders with your actual data."