
distibute: build $(BUILD_IMAGES) $(BUILD_LANG_IMAGES)

$(BUILD_IMAGES): %:
$(BUILD_LANG_IMAGES): %:

%:
	docker tag $(PRODUCT_IMAGE_BASE)/$@:glibc-$(PROJECT_VERSION) $(DISTO_REGISTRY)/$@:glibc-$(PROJECT_VERSION)
	docker push $(DISTO_REGISTRY)/$@:glibc-$(PROJECT_VERSION)
