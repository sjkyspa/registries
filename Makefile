DOCKER_BUILD_OPTS=--build-arg https_proxy=$(http_proxy) --build-arg http_proxy=$(http_proxy) --build-arg HTTP_PROXY=$(http_proxy) --build-arg HTTPS_PROXY=$(http_proxy)
setup:
	@find . -name "Dockerfile.template" |xargs -I{} sh -c "sed -e 's#{{REGISTRY}}#$$REGISTRY#g' -e 's#{{VERSION}}#$$REGISTRY_VERSION#g' {} > \$$(echo {} | sed 's#.template##g')"
	@for folder in $$(find . -depth -maxdepth 2 -name "Dockerfile"  -print); do \
		pushd $$(dirname $$folder) &>/dev/null; \
		image=$$(echo $$folder | cut -c3- | sed 's/^[0-9]*-//g'); \
		echo "Building the $$image"; \
		docker build -q $(DOCKER_BUILD_OPTS) -t $$(dirname $$image) . ; \
		echo "Build $$image success"; \
		docker tag -f $$(dirname $$image) $$REGISTRY/$$(dirname $$image); \
		echo "pushing $$REGISTRY/$$(dirname $$image)"; \
		docker push $$REGISTRY/$$(dirname $$image); \
		echo "push $$REGISTRY/$$(dirname $$image) success"; \
		popd &>/dev/null ;\
	done
