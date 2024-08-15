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
