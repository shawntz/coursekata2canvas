.PHONY: run deploy help

help:
	@echo "Available targets:"
	@echo "  make run     - Run the Shiny app locally"
	@echo "  make deploy  - Deploy the Shiny app"

run:
	R -e "shiny::runApp('app.R')"

deploy:
	R -e "rsconnect::deployApp()"
