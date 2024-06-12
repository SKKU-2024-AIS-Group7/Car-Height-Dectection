import requests
import os

url = os.getenv("SAGEMAKER_ENDPOINT")
image_path = 'sample.jpg'

with open(image_path, 'rb') as img_file:
    headers = {'Content-Type': 'application/x-image'}
    response = requests.post(url, headers=headers, data=img_file)

print(response.json())
