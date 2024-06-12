FROM pytorch/pytorch:1.8.0-cuda11.1-cudnn8-runtime

WORKDIR /opt/program

RUN apt-get update && apt-get install -y \
    python3-pip \
    libgl1-mesa-glx \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir \
    torch \
    torchvision \
    scikit-learn \
    opencv-python-headless \
    numpy \
    pillow \
    joblib

COPY ./apps/infra/model /opt/program

ENTRYPOINT ["python3", "inference.py"]
