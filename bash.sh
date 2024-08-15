#!/bin/bash

# Build the Vue application
npm run build

# Create a Netlify configuration file in the root directory
cat <<EOT > netlify.toml
[build]
  publish = "dist"
  command = "npm run build"
EOT

# Authenticate with Netlify CLI
netlify login

# Initialize a new site on Netlify
netlify init

# Deploy to Netlify
netlify deploy --prod

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

# Set environment variables on Netlify
echo "Setting environment variables on Netlify..."
netlify env:set CLIENT_ID abc123
netlify env:set CLIENT_SECRET xyz789
netlify env:set REDIRECT_URI https://your-site-name.netlify.app/callback

echo "Deployment and setup complete."