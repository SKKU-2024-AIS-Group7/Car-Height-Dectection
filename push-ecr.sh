docker build -t car-height-detection -f apps/infra/model/Dockerfile .
aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin 637423379250.dkr.ecr.ap-northeast-2.amazonaws.com
docker tag car-height-detection:latest 637423379250.dkr.ecr.ap-northeast-2.amazonaws.com/car-height-detection:latest
docker push 637423379250.dkr.ecr.ap-northeast-2.amazonaws.com/car-height-detection:latest
