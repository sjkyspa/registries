setup:
	@find . -name "Dockerfile.template" |xargs -I{} sh -c "sed -e 's#{{REGISTRY}}#$$REGISTRY#g' {} > \$$(echo {} | sed 's#.template##g')"
	for image in $$(find . -name "Dockerfile" -depth 2 -print | cut -c3-); do \
		pushd $$(dirname $$image) &> /dev/null; \
		docker build -t $$(dirname $$image) . ; \
		docker tag -f $$(dirname $$image) $$REGISTRY/$$(dirname $$image) ; \
		docker push $$REGISTRY/$$(dirname $$image) ; \
		popd &>/dev/null ;\
	done