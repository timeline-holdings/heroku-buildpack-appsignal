.PHONY: test clean

test:
	@echo "Building Docker image (using test/Dockerfile) and running the test suite..."
	docker build -t appsignal-buildpack-test -f test/Dockerfile .
	docker run --rm appsignal-buildpack-test

clean:
	@echo "Cleaning up Docker test image..."
	docker rmi appsignal-buildpack-test || true
