setup:
	@find . -name "Dockerfile.template" |xargs -I{} sh -c "sed -e 's#{{REGISTRY}}#$$REGISTRY#g' -e 's#{{VERSION}}#$$REGISTRY_VERSION#g' {} > \$$(echo {} | sed 's#.template##g')"
	@for folder in $$(find . -name "Dockerfile" -depth 2 -print); do \
		pushd $$(dirname $$folder) &>/dev/null; \
		image=$$(echo $$folder | cut -c3- | sed 's/^[0-9]*-//g'); \
		echo "Building the $$image"; \
		docker build -q -t $$(dirname $$image) . ; \
		echo "Build $$image success"; \
		docker tag $$(dirname $$image) $$REGISTRY/$$(dirname $$image); \
		echo "pushing $$REGISTRY/$$(dirname $$image)"; \
		docker push $$REGISTRY/$$(dirname $$image); \
		echo "push $$REGISTRY/$$(dirname $$image) success"; \
		popd &>/dev/null ;\
	done
