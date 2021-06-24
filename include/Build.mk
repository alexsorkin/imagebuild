
habitus:
	PRODUCT_IMAGE_BASE=$(PRODUCT_IMAGE_BASE) habitus -keep-all -force-rmi

build: habitus $(BUILD_IMAGES) $(BUILD_LANG_IMAGES)

$(BUILD_IMAGES): %:
$(BUILD_LANG_IMAGES): %:

%:
	docker tag $(PRODUCT_IMAGE_BASE)/$@ $(PRODUCT_IMAGE_BASE)/$@:glibc-$(PROJECT_VERSION)
