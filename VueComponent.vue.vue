<template>
    <div>
    <button @click="redirectToOracleLogin" > Login with Oracle </button>
    < input type = "file" @change="handleFileUpload" multiple >
        <button @click="compressAndUploadFiles" > Upload to OCI </button>
            </div>
            </template>

            <script>
import axios from 'axios';
import { compressFiles, uploadToOCI } from './oci-utils'; // Import your utility functions

export default {
    data() {
        return {
            files: [],
            accessToken: null
        };
    },
    methods: {
        redirectToOracleLogin() {
            const clientId = 'YOUR_CLIENT_ID';
            const redirectUri = 'YOUR_REDIRECT_URI';
            const ociLoginUrl = `https://login.ap-sydney-1.oraclecloud.com/v2/ui/domains?client_id=${clientId}&redirect_uri=${encodeURIComponent(redirectUri)}&response_type=code&scope=openid`;
            window.location.href = ociLoginUrl;
        },
        handleFileUpload(event) {
            this.files = Array.from(event.target.files);
        },
        async compressAndUploadFiles() {
            try {
                const compressedFilePath = await compressFiles(this.files, 'output.tar.gz');
                const response = await uploadToOCI('your-bucket-name', 'output.tar.gz', compressedFilePath, this.accessToken);
                console.log('Upload successful:', response);
            } catch (error) {
                console.error('Error uploading files:', error);
            }
        }
    },
    async mounted() {
        const urlParams = new URLSearchParams(window.location.search);
        const authorizationCode = urlParams.get('code');

        if (authorizationCode) {
            const tokenResponse = await axios.get(`/oauth2/callback?code=${authorizationCode}`);
            this.accessToken = tokenResponse.data.access_token;
        }
    }
};
</script>