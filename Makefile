TAG:=$(shell git log -1 --pretty=format:"%H")
TAG-DEV:=$(TAG)-dev
TAG-LATEST:=$(TAG)-latest
TAG-PROD:=$(TAG)-prod
AWS_CONTAINER_REGISTRY_URL:=294290347293.dkr.ecr.us-east-1.amazonaws.com/
CONTAINER_NAME:=acv-img-proxy
CONTAINER_URL:=$(AWS_CONTAINER_REGISTRY_URL)$(CONTAINER_NAME)

build-dev:
	docker build -t $(CONTAINER_NAME) -f Dockerfile.dev .

build-latest:
	docker build -t $(CONTAINER_NAME) -f Dockerfile.latest .

build-prod:
	docker build -t $(CONTAINER_NAME) -f Dockerfile.prod .

aws-ecr-login:
	eval $(shell aws ecr get-login --no-include-email --region us-east-1)

pushcontainer-dev: aws-ecr-login
	docker tag $(CONTAINER_NAME):latest $(CONTAINER_URL):$(TAG-DEV)
	docker tag $(CONTAINER_URL):$(TAG-DEV) $(CONTAINER_URL):latest
	docker push $(CONTAINER_URL):latest
	docker push $(CONTAINER_URL):$(TAG-DEV)

pushcontainer-latest: aws-ecr-login
	docker tag $(CONTAINER_NAME):latest $(CONTAINER_URL):$(TAG-LATEST)
	docker tag $(CONTAINER_URL):$(TAG-LATEST) $(CONTAINER_URL):latest
	docker push $(CONTAINER_URL):latest
	docker push $(CONTAINER_URL):$(TAG-LATEST)

pushcontainer-prod: aws-ecr-login
	docker tag $(CONTAINER_NAME):latest $(CONTAINER_URL):$(TAG-PROD)
	docker tag $(CONTAINER_URL):$(TAG-PROD) $(CONTAINER_URL):latest
	docker push $(CONTAINER_URL):latest
	docker push $(CONTAINER_URL):$(TAG-PROD)

updatek8s-dev:
	kubectl config use-context dev
	kubectl replace -f kubernetes/dev/deployment.yml --record
	kubectl set image deployment/acv-img-proxy-deployment acv-img-proxy='$(CONTAINER_URL):$(TAG-DEV)' --record
	kubectl rollout status deployment/acv-img-proxy-deployment
	kubectl config use-context default

updatek8s-latest:
	kubectl config use-context default
	kubectl replace -f kubernetes/latest/deployment.yml --record
	kubectl set image deployment/acv-img-proxy-deployment acv-img-proxy='$(CONTAINER_URL):$(TAG-LATEST)' --record
	kubectl rollout status deployment/acv-img-proxy-deployment
	kubectl config use-context default

updatek8s-prod:
	kubectl config use-context prod
	kubectl replace -f kubernetes/prod/deployment.yml --record
	kubectl set image deployment/acv-img-proxy-deployment acv-img-proxy='$(CONTAINER_URL):$(TAG-PROD)' --record
	kubectl rollout status deployment/acv-img-proxy-deployment
	kubectl config use-context default

deploy-dev: build-dev pushcontainer-dev updatek8s-dev

deploy-latest: build-latest pushcontainer-latest updatek8s-latest

deploy-prod: build-prod pushcontainer-prod updatek8s-prod

docker-run:
	docker build -t acv-img-proxy .
	docker run -p 8080:8000 -e "PRIMARY_S3_HOST=static-dev.acvauctions.com.s3.amazonaws.com" -e "BACKUP_S3_HOST=my-vehicle-photos.s3.amazonaws.com" acv-img-proxy:latest 
