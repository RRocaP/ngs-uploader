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
      const ociLoginUrl = `https://login.ap-sydney-1.oraclecloud.com/v2/ui/domains?client_id=${clientId}&redirect_uri=${encodeURIComponent(redirectUri)}&response_type=code&scope=`;
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
        const tokenResponse = await axios.get(`/.netlify/functions/oauth2-callback?code=${authorizationCode}`);
        this.accessToken = tokenResponse.data.access_token;
      }
    } catch (error) {
      console.error('Error during OAuth callback:', error.response ? error.response.data : error.message);
    }
  }
};
</script>
