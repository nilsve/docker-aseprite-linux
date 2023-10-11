IMAGE_NAME := docker-aseprite

build: build-image
	docker run --rm \
	-v ${PWD}/output:/output \
	-v ${PWD}/dependencies:/dependencies \
	${IMAGE_NAME}

build-compose:
	docker-compose build
	docker-compose up

build-image:
	docker build -t ${IMAGE_NAME} .