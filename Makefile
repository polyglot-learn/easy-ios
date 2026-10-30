.PHONY: validate check-links

validate:
	python3 scripts/validate_catalog.py

check-links:
	bash scripts/check_links.sh
