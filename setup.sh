#!/usr/bin/env bash

set -ex

# Check requirements: npm
if [ ! $(command -v npm) ]
then
  echo "Error: npm is not installed. Please install npm first."
  exit 1
fi

BASEDIR=$(dirname $(realpath $0))

cd $BASEDIR

# Install libGL.so.1
sudo apt update
sudo apt install libgl1-mesa-glx -y

# Install Dependencies
pip3 install -r ./requirements.txt

# Clone YoloV5 Repository
if [ ! -d "./yolov5" ]; then
  git clone https://github.com/ultralytics/yolov5.git
  cd yolov5
  pip install -r requirements.txt
  # remove git
  rm -rf .git
else
  echo "yolov5 repository is already downloaded then skip cloning..."
fi

cd $BASEDIR

# Download Image Datasets
if [ ! -d "./yolov5/data/train" ]; then
  FILE_ID="1gzQY1eYRf1YCQwzEpD2u18NVKEbNNSH7"
  TAR_FILE_NAME="image-data.tar"
  gdown $FILE_ID -O $TAR_FILE_NAME

  tar -xvf $TAR_FILE_NAME

  EXTRACTED_DIR="image-data"

  mkdir -p ./yolov5/data
  cp -r $EXTRACTED_DIR/* ./yolov5/data/

  rm -f $TAR_FILE_NAME
  rm -rf $EXTRACTED_DIR

  # Remove ._ files
  find ./yolov5/data/ -name '._*' -exec rm {} +
  rm ._image-data
else
  echo "image data set is already downloaded then skip download..."
fi

# Ignore ipynb cell output when commit
nbstripout --install

echo "HUGGINGFACE_TOKEN=YOUR-TOKEN-HERE" >> .env

echo "Devcontainer Setup Finished"