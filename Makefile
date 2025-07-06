.PHONY: help install build test deploy clean docs lint format

# Default target
help: ## Show this help message
	@echo "Sui AI SDK - Development Commands"
	@echo "================================="
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $1, $2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($0, 5) } ' $(MAKEFILE_LIST)

##@ Development

install: ## Install all dependencies
	@echo "Installing dependencies..."
	npm install
	cd sdk && npm install
	cd tools/cli && npm install
	cd docs && npm install

build: ## Build all packages
	@echo "Building Move contracts..."
	cd move && sui move build
	@echo "Building TypeScript SDK..."
	cd sdk && npm run build
	@echo "Building CLI tools..."
	cd tools/cli && npm run build
	@echo "Building documentation..."
	cd docs && npm run build

test: ## Run all tests
	@echo "Testing Move contracts..."
	cd move && sui move test
	@echo "Testing TypeScript SDK..."
	cd sdk && npm test
	@echo "Testing CLI tools..."
	cd tools/cli && npm test
	@echo "Running integration tests..."
	cd examples && npm test

lint: ## Run linting
	@echo "Linting TypeScript SDK..."
	cd sdk && npm run lint
	@echo "Linting CLI tools..."
	cd tools/cli && npm run lint

format: ## Format code
	@echo "Formatting TypeScript SDK..."
	cd sdk && npm run format
	@echo "Formatting CLI tools..."
	cd tools/cli && npm run format

##@ Deployment

deploy-testnet: ## Deploy to Sui testnet
	@echo "Deploying to testnet..."
	./scripts/deploy.sh testnet

deploy-mainnet: ## Deploy to Sui mainnet
	@echo "Deploying to mainnet..."
	./scripts/deploy.sh mainnet

##@ Utilities

clean: ## Clean build artifacts
	@echo "Cleaning build artifacts..."
	rm -rf sdk/dist
	rm -rf tools/cli/dist
	rm -rf docs/dist
	rm -rf move/build

docs: ## Generate documentation
	@echo "Generating documentation..."
	cd docs && npm run build
	@echo "Documentation available at docs/dist/index.html"

docker-up: ## Start Docker development environment
	@echo "Starting Docker environment..."
	docker-compose up -d

docker-down: ## Stop Docker development environment
	@echo "Stopping Docker environment..."
	docker-compose down

logs: ## Show Docker logs
	docker-compose logs -f

##@ Release

version-patch: ## Bump patch version
	npm version patch
	cd sdk && npm version patch
	cd tools/cli && npm version patch

version-minor: ## Bump minor version
	npm version minor
	cd sdk && npm version minor
	cd tools/cli && npm version minor

version-major: ## Bump major version
	npm version major
	cd sdk && npm version major
	cd tools/cli && npm version major

publish: ## Publish to NPM
	@echo "Publishing to NPM..."
	cd sdk && npm publish --access public
	cd tools/cli && npm publish --access public

##@ Monitoring

status: ## Check deployment status
	@echo "Checking deployment status..."
	curl -s https://api.sui-ai-sdk.com/health || echo "Service unavailable"

metrics: ## Show performance metrics
	@echo "Performance metrics:"
	curl -s https://api.sui-ai-sdk.com/metrics || echo "Metrics unavailable"

##@ Development Tools

setup-git-hooks: ## Setup Git hooks
	@echo "Setting up Git hooks..."
	cp scripts/pre-commit .git/hooks/
	chmod +x .git/hooks/pre-commit
	cp scripts/pre-push .git/hooks/
	chmod +x .git/hooks/pre-push

init-project: ## Initialize new project
	@echo "Initializing Sui AI SDK project..."
	npm run init

##@ Examples

run-examples: ## Run example applications
	@echo "Running examples..."
	cd examples && npm start

demo: ## Run interactive demo
	@echo "Starting interactive demo..."
	cd examples && npm run demo