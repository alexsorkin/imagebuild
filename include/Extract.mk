
extract: build
	docker build -f build/Dockerfile.selenium build
	docker save $(EXTRACT_IMAGES) | gzip > $(EXTRACT_DIRECTORY)/blueocean-operator-repo.tar.gz
	docker save $(EXTRACT_RUNTIME_IMAGES) | gzip > $(EXTRACT_DIRECTORY)/blueocean-builders-repo.tar.gz
	docker save $(SELENIUM_RUNTIME_IMAGES) | gzip > $(EXTRACT_DIRECTORY)/blueocean-selenium-repo.tar.gz
