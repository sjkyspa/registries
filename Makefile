build:
	@find . -name "Dockerfile.template" |xargs -I{} sh -c "sed -e 's#{{REGISTRY}}#$$REGISTRY#g' {} > \$$(echo {} | sed 's#.template##g')"


push: check-registry push-build-wrapper push-verify-wrapper
	@docker tag -f $(IMAGE) $(DEV_IMAGE)
	@docker push $(DEV_IMAGE)