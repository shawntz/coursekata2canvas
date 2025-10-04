.PHONY: run deploy help

# Configuration
APP_NAME ?= coursekata2canvas

help:
	@echo "Available targets:"
	@echo "  make run            - Run the Shiny app locally"
	@echo "  make deploy         - Deploy the Shiny app"
	@echo ""
	@echo "Configuration:"
	@echo "  APP_NAME=$(APP_NAME)  - Set app name with APP_NAME=yourname make deploy"

run:
	R -e "shiny::runApp('app.R')"

deploy:
	R -e "rsconnect::deployApp(appName='$(APP_NAME)', forceUpdate=TRUE)"
