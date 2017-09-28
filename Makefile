TAG:=$(shell git log -1 --pretty=format:"%H")
AWS_CONTAINER_REGISTRY_URL:=294290347293.dkr.ecr.us-east-1.amazonaws.com/
CONTAINER_NAME:=acv-img-proxy
CONTAINER_URL:=$(AWS_CONTAINER_REGISTRY_URL)$(CONTAINER_NAME)


build:
	docker build -t $(CONTAINER_NAME) .

pushcontainer:
	eval $(shell aws ecr get-login --no-include-email --region us-east-1)
	docker tag $(CONTAINER_NAME):latest $(CONTAINER_URL):$(TAG)
	docker tag $(CONTAINER_URL):$(TAG) $(CONTAINER_URL):latest
	docker push $(CONTAINER_URL):latest
	docker push $(CONTAINER_URL):$(TAG)

updatek8s-dev:
	kubectl config use-context dev
	kubectl replace -f deployment.yml --record
	kubectl set image deployment/acv-img-proxy-deployment acv-img-proxy='$(CONTAINER_URL):$(TAG)' --record
	kubectl rollout status deployment/acv-img-proxy-deployment
	kubectl config use-context default

deploy-dev: build pushcontainer updatek8s-dev
