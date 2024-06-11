FROM pytorch/pytorch:1.8.0-cuda11.1-cudnn8-runtime

WORKDIR /opt/program

RUN apt-get update && apt-get install -y \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir \
    torch \
    torchvision \
    opencv-python \
    scikit-learn \
    boto3 \
    joblib \
    pillow

COPY . /opt/program

ENTRYPOINT ["python3", "inference.py"]
