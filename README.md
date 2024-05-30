## Vehicle Height Detection System using Deep Learning-based Image Processing
2024-1 성균관대학교 AI 시스템 7조 팀 프로젝트 레포지토리

### 1. 주제
논문 구현: 딥러닝 기반 이미지 처리를 이용한 통행 차량 높이검출 시스템(정재호 외 2인, 2021)

### 2. 프로젝트 Spec
python 버전: 3.11 (cpython)
dependencies: requiresments.txt에 정의됨

### 3. 실행 방법
**vscode + devcontainer 실행 (추가 설정 필요 x)**
vscode 및 docker 설치 후, vscode devcontainer extension으로 실행 하는 것을 권장합니다.

**local에서 실행 (추가 설정 필요)**
아래 bash 명령어 실행
```bash
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

echo "Setup Finished"
```
