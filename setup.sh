#!/usr/bin/env bash

set -ex

# Install libGL.so.1
sudo apt update
sudo apt install libgl1-mesa-glx -y

# Install Dependencies
pip3 install -r ./requirements.txt