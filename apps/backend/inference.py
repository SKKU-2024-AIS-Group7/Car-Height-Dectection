import boto3

client = boto3.client("sagemaker-runtime")

image_path = "sample.jpg"

with open(image_path, "rb") as image_file:
    payload = image_file.read()

endpoint_name = "pytorch-model-endpoint"
content_type = "image/jpeg"
accept = "application/json"
response = client.invoke_endpoint(
    EndpointName=endpoint_name, ContentType=content_type, Accept=accept, Body=payload
)

print(response)
