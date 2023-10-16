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

# Create a GitHub runner Token
TOKEN=$(curl -X POST \
             -H "Authorization: token $GITHUB_PAT" \
             -H "Accept: application/vnd.github.v3+json" \
             https://api.github.com/repos/alfredodeza/azure-spot-runner/actions/runners/registration-token | grep token | cut -d '"' -f 4)


# Configure the runner
$WORK_DIR/config.sh --unattended --url https://github.com/alfredodeza/azure-spot-runner --token $TOKEN
