
.PHONY: help all clean pkg webpages

help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n"} /^[a-zA-Z_-]+:.*?##/ { printf " \033[36mmake %-17s\033[0m #%s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

all: pkg webpages ## Build all

clean: ## Clean package and public folder
	@rm -rf public *.deb

pkg: ## Build Debian Package
	./make-package-debian

webpages: pkg ## Build public webpages for GitLab CI pages
	./make-webpages
