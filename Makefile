.PHONY: validate check-links new test test-examples format lint

validate:
	python3 scripts/validate_catalog.py

check-links:
	bash scripts/check_links.sh

# make new NAME=MyApp CATEGORY=productivity [SYMBOL=star.fill] [COLOR=0A84FF] [DEVICES=ipad] [BUNDLE_ID=com.example.myapp]
new:
	@test -n "$(NAME)" -a -n "$(CATEGORY)" || { echo "usage: make new NAME=MyApp CATEGORY=productivity [SYMBOL=star.fill] [COLOR=0A84FF] [DEVICES=universal|iphone|ipad] [BUNDLE_ID=com.example.myapp]"; exit 2; }
	python3 scripts/new_app.py $(NAME) --category $(CATEGORY) $(if $(SYMBOL),--symbol $(SYMBOL)) $(if $(COLOR),--color $(COLOR)) $(if $(DEVICES),--devices $(DEVICES)) $(if $(BUNDLE_ID),--bundle-id $(BUNDLE_ID))

# make test APP=examples/Tasks
test:
	@test -n "$(APP)" || { echo "usage: make test APP=examples/Tasks"; exit 2; }
	bash scripts/test_app.sh $(APP)

test-examples:
	@for app in examples/*/; do bash scripts/test_app.sh "$${app%/}" || exit 1; done

format:
	xcrun swift-format format --in-place --recursive --parallel examples scripts/make_icon.swift

lint:
	xcrun swift-format lint --strict --recursive --parallel examples scripts/make_icon.swift
