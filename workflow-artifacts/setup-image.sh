#!/bin/bash
#
# Setup the runner to have the Azure CLI pre-installed as well as the Actions
# Runner

# Define a working directory
WORK_DIR="/opt/actions-runner"

# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Create a folder
mkdir -p $WORK_DIR && cd $WORK_DIR

# Download the latest runner package
curl -O -L https://github.com/actions/runner/releases/download/v2.310.2/actions-runner-linux-x64-2.310.2.tar.gz

# Extract the installer
tar xzf $WORK_DIR/actions-runner-linux-x64-2.310.2.tar.gz

# Configure the runner
$WORK_DIR/config.sh --url https://github.com/alfredodeza/azure-spot-runner --token $GITHUB_PAT

# Schedule the runner to start immediately but in the background
echo "$WORK_DIR/run.sh" | at now +1 minutes
