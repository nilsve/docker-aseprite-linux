IMAGE_NAME := docker-aseprite

.PHONY: build build-compose build-image clean

clean:
	sudo rm -rf ./output ./dependencies 2>/dev/null || true

build: build-image
	docker run -it --rm \
	-v ${PWD}/output:/output \
	-v ${PWD}/dependencies:/dependencies \
	${IMAGE_NAME} $(ARGS)

build-compose:
	docker-compose build
	docker-compose up

build-image:
	docker build -t ${IMAGE_NAME} .