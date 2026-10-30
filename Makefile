.PHONY: validate check-links new

validate:
	python3 scripts/validate_catalog.py

check-links:
	bash scripts/check_links.sh

# make new NAME=MyApp CATEGORY=productivity [SYMBOL=star.fill] [COLOR=0A84FF]
new:
	@test -n "$(NAME)" -a -n "$(CATEGORY)" || { echo "usage: make new NAME=MyApp CATEGORY=productivity [SYMBOL=star.fill] [COLOR=0A84FF]"; exit 2; }
	python3 scripts/new_app.py $(NAME) --category $(CATEGORY) $(if $(SYMBOL),--symbol $(SYMBOL)) $(if $(COLOR),--color $(COLOR))
