.PHONY: help setup build test clean lint format check install-tools ios macos coverage

# iOS simulator destination: the newest available iPhone simulator, picked at
# run time. Override with e.g. make test-ios IOS_DESTINATION="platform=iOS Simulator,name=iPhone 17"
# Detected lazily (only by targets that use it) and at most once per make run.
IOS_DESTINATION ?= $(eval IOS_DESTINATION := $$(shell scripts/ios-simulator-destination.sh))$(IOS_DESTINATION)

# Default target
help: ## Show this help message
	@echo "TicTacToe Development Commands"
	@echo "=============================="
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Setup and installation
setup: install-tools ## Set up the development environment
	@echo "✅ Development environment setup complete"

install-tools: ## Install development tools (macOS)
	@echo "🔧 Installing development tools..."
	@command -v brew >/dev/null 2>&1 || { echo "Please install Homebrew first"; exit 1; }
	@brew install swiftlint || echo "SwiftLint already installed"
	@command -v swift-format >/dev/null 2>&1 || { echo "Installing swift-format..."; \
		git clone https://github.com/apple/swift-format.git /tmp/swift-format && \
		cd /tmp/swift-format && swift build -c release && \
		sudo cp .build/release/swift-format /usr/local/bin/ && \
		rm -rf /tmp/swift-format; }

# Building
build: ## Build the project using Swift Package Manager
	@echo "🔨 Building project..."
	@swift build

build-ios: ## Build iOS target using xcodebuild
	@echo "📱 Building iOS target..."
	@test -n '$(IOS_DESTINATION)' || { echo "No available iPhone simulator found"; exit 1; }
	@xcodebuild clean build \
		-project tictactoe.xcodeproj \
		-scheme "tictactoe iOS" \
		-destination '$(IOS_DESTINATION)' \
		CODE_SIGN_IDENTITY="" \
		CODE_SIGNING_REQUIRED=NO

build-macos: ## Build macOS target using xcodebuild
	@echo "💻 Building macOS target..."
	@xcodebuild clean build \
		-project tictactoe.xcodeproj \
		-scheme "tictactoe macOS" \
		-destination "platform=macOS"

# Testing
test: ## Run all tests using Swift Package Manager
	@echo "🧪 Running tests..."
	@swift test

test-ios: ## Run iOS tests using xcodebuild
	@echo "📱 Running iOS tests..."
	@test -n '$(IOS_DESTINATION)' || { echo "No available iPhone simulator found"; exit 1; }
	@xcodebuild test \
		-project tictactoe.xcodeproj \
		-scheme "tictactoe iOS" \
		-destination '$(IOS_DESTINATION)' \
		-testPlan "tictactoeTests" \
		CODE_SIGN_IDENTITY="" \
		CODE_SIGNING_REQUIRED=NO

test-macos: ## Run macOS tests using xcodebuild
	@echo "💻 Running macOS tests..."
	@xcodebuild test \
		-project tictactoe.xcodeproj \
		-scheme "tictactoe macOS" \
		-destination "platform=macOS" \
		-testPlan "tictactoeTests"

coverage: ## Generate code coverage report
	@echo "📊 Generating coverage report..."
	@swift test --enable-code-coverage
	@xcrun llvm-cov show .build/debug/TicTacToeCorePackageTests.xctest/Contents/MacOS/TicTacToeCorePackageTests \
		-instr-profile=.build/debug/codecov/default.profdata \
		-format=html -output-dir=coverage-report || echo "Coverage report generation requires Xcode tests"

# Code quality
lint: ## Run SwiftLint
	@echo "🔍 Running SwiftLint..."
	@swiftlint

lint-fix: ## Run SwiftLint with auto-fix
	@echo "🔧 Running SwiftLint with auto-fix..."
	@swiftlint --fix

format: ## Format code using swift-format
	@echo "🎨 Formatting code..."
	@swift-format --in-place --recursive .

format-check: ## Check code formatting without making changes
	@echo "🔍 Checking code formatting..."
	@swift-format lint --recursive .

check: lint format-check test ## Run all quality checks

# Utility commands
clean: ## Clean build artifacts
	@echo "🧹 Cleaning build artifacts..."
	@swift package clean || echo "No SPM build to clean"
	@rm -rf .build
	@rm -rf DerivedData
	@rm -rf coverage-report
	@xcodebuild clean -project tictactoe.xcodeproj -alltargets || echo "No Xcode build to clean"

reset: clean ## Reset the development environment
	@echo "🔄 Resetting development environment..."
	@rm -rf .swiftpm
	@rm -rf Package.resolved

ios: build-ios test-ios ## Build and test iOS target

macos: build-macos test-macos ## Build and test macOS target

all: check ios macos ## Run all checks and build all targets

# Git hooks
install-hooks: ## Install Git pre-commit hooks
	@echo "🔗 Installing Git hooks..."
	@cp .devcontainer/setup.sh .git/hooks/pre-commit || echo "Setup script not found"
	@chmod +x .git/hooks/pre-commit

# Performance benchmarking
benchmark: ## Run performance benchmarks
	@echo "🚀 Running performance benchmarks..."
	@swift scripts/benchmark.swift

# Development commands
dev: ## Start development mode (format, lint, test)
	@make format
	@make lint
	@make test
	@echo "🚀 Ready for development!"

ci: ## Simulate CI environment locally
	@echo "🤖 Simulating CI environment..."
	@make check
	@make ios
	@make macos
	@echo "✅ CI simulation complete"