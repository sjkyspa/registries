setup:
	@find . -name "Dockerfile.template" |xargs -I{} sh -c "sed -e 's#{{REGISTRY}}#$$REGISTRY#g' {} > \$$(echo {} | sed 's#.template##g')"
	@for folder in $$(find . -name "Dockerfile" -depth 2 -print); do \
		pushd $$(dirname $$folder) &>/dev/null; \
		image=$$(echo $$folder | cut -c3- | sed 's/^[0-9]*-//g'); \
		echo "build the $$image"; \
		docker build -t $$(dirname $$image) . ; \
		docker tag -f $$(dirname $$image) $$REGISTRY/$$(dirname $$image); \
		echo "push to $$REGISTRY/$$(dirname $$image)"; \
		docker push $$REGISTRY/$$(dirname $$image); \
		popd &>/dev/null ;\
	done