#!/usr/bin/env bash

set -ex

BASEDIR=$(dirname $(realpath $0))

cd $BASEDIR

# Install libGL.so.1
sudo apt update
sudo apt install libgl1-mesa-glx -y

# Install Dependencies
pip3 install -r ./requirements.txt

# Ignore ipynb cell output when commit
nbstripout --install

# Create env file
if [ ! -f ".env" ]; then
    echo "HUGGINGFACE_TOKEN=YOUR-TOKEN-HERE" >> .env
    echo "ROBOFLOW_TOKEN=YOUR-TOKEN-HERE" >> .env
    echo "SAGEMAKER_ENDPOINT=YOUR-URL-HERE" >> .env
else
    echo ".env file already exists then skip creating..."
fi

echo "Devcontainer Setup Finished"