TAG:=$(shell git log -1 --pretty=format:"%H")
AWS_CONTAINER_REGISTRY_URL:=294290347293.dkr.ecr.us-east-1.amazonaws.com/
CONTAINER_NAME:=acv-img-proxy
CONTAINER_URL:=$(AWS_CONTAINER_REGISTRY_URL)$(CONTAINER_NAME)

build:
	docker build -t $(CONTAINER_NAME) .

aws-ecr-login:
	eval $(shell aws ecr get-login --no-include-email --region us-east-1)

pushcontainer: aws-ecr-login
	docker tag $(CONTAINER_NAME):latest $(CONTAINER_URL):$(TAG)
	docker tag $(CONTAINER_URL):$(TAG) $(CONTAINER_URL):latest
	docker push $(CONTAINER_URL):latest
	docker push $(CONTAINER_URL):$(TAG)

updatek8s-dev:
	kubectl config use-context dev
	kubectl replace -f kubernetes/dev/deployment.yml --record
	kubectl set image deployment/acv-img-proxy-deployment acv-img-proxy='$(CONTAINER_URL):$(TAG)' --record
	kubectl rollout status deployment/acv-img-proxy-deployment
	kubectl config use-context default

updatek8s-latest:
	kubectl config use-context default
	kubectl replace -f kubernetes/latest/deployment.yml --record
	kubectl set image deployment/acv-img-proxy-deployment acv-img-proxy='$(CONTAINER_URL):$(TAG)' --record
	kubectl rollout status deployment/acv-img-proxy-deployment
	kubectl config use-context default

updatek8s-prod:
	kubectl config use-context prod
	kubectl replace -f kubernetes/prod/deployment.yml --record
	kubectl set image deployment/acv-img-proxy-deployment acv-img-proxy='$(CONTAINER_URL):$(TAG)' --record
	kubectl rollout status deployment/acv-img-proxy-deployment
	kubectl config use-context default

deploy-dev: build pushcontainer updatek8s-dev

deploy-latest: build pushcontainer updatek8s-latest

deploy-prod: build pushcontainer updatek8s-prod

run:
	docker build -t acv-img-proxy .
	docker run -p 8080:8000 -e "S3_HOST=s3.amazonaws.com" -e "S3_PATH_PREFIX=static-dev.acvauctions.com/" acv-img-proxy:latest
