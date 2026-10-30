.PHONY: validate check-links new test test-examples

validate:
	python3 scripts/validate_catalog.py

check-links:
	bash scripts/check_links.sh

# make new NAME=MyApp CATEGORY=productivity [SYMBOL=star.fill] [COLOR=0A84FF]
new:
	@test -n "$(NAME)" -a -n "$(CATEGORY)" || { echo "usage: make new NAME=MyApp CATEGORY=productivity [SYMBOL=star.fill] [COLOR=0A84FF]"; exit 2; }
	python3 scripts/new_app.py $(NAME) --category $(CATEGORY) $(if $(SYMBOL),--symbol $(SYMBOL)) $(if $(COLOR),--color $(COLOR))

# make test APP=examples/Tasks
test:
	@test -n "$(APP)" || { echo "usage: make test APP=examples/Tasks"; exit 2; }
	bash scripts/test_app.sh $(APP)

test-examples:
	@for app in examples/*/; do bash scripts/test_app.sh "$${app%/}" || exit 1; done
