#!/usr/bin/env bash

set -ex

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
  echo "yolov5 repository is already cloned then skip cloning..."
fi

cd $BASEDIR

# Download Image Datasets - YOLO based
if [ ! -d "./yolov5/data/yolo/train" ]; then
  FILE_ID="1oKYkOO8jqk_jic_26IiaxILnvuj_vB1Q"
  TAR_FILE_NAME="yolo.tar"
  gdown $FILE_ID -O $TAR_FILE_NAME

  tar -xvf $TAR_FILE_NAME

  EXTRACTED_DIR="yolo"

  mkdir -p ./yolov5/data/yolo
  cp -r $EXTRACTED_DIR/* ./yolov5/data/yolo

  rm -f $TAR_FILE_NAME
  rm -rf $EXTRACTED_DIR

  # Remove ._ files
  find ./yolov5/data/ -name '._*' -exec rm {} +
  rm ._yolo
else
  echo "image data set is already downloaded then skip download..."
fi

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