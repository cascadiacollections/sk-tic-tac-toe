#!/bin/bash

# DevContainer setup script for TicTacToe Swift project

set -e

echo "🚀 Setting up TicTacToe development environment..."

# Display versions
echo "📦 Tool versions:"
echo "Swift: $(swift --version)"
echo "SwiftLint: $(swiftlint version)"
echo "swift-format: $(swift-format --version)"

# Set up git configuration if not already configured
if [ -z "$(git config --get user.name)" ]; then
    echo "⚙️  Configuring Git (you can change these later)..."
    git config --global user.name "Developer"
    git config --global user.email "dev@example.com"
    git config --global init.defaultBranch main
fi

# Install pre-commit hooks if the directory exists
if [ -d ".git" ]; then
    echo "🔗 Setting up Git hooks..."
    
    # Create pre-commit hook
    cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash

echo "Running pre-commit checks..."

# Run SwiftLint
if command -v swiftlint >/dev/null 2>&1; then
    echo "🔍 Running SwiftLint..."
    swiftlint --strict
    if [ $? -ne 0 ]; then
        echo "❌ SwiftLint failed. Please fix the issues and try again."
        exit 1
    fi
else
    echo "⚠️  SwiftLint not found, skipping..."
fi

# Run swift-format check
if command -v swift-format >/dev/null 2>&1; then
    echo "🎨 Checking Swift formatting..."
    if ! swift-format lint --recursive . > /dev/null 2>&1; then
        echo "❌ Code formatting issues found. Run 'swift-format --in-place --recursive .' to fix."
        exit 1
    fi
else
    echo "⚠️  swift-format not found, skipping..."
fi

echo "✅ Pre-commit checks passed!"
EOF

    # Make the pre-commit hook executable
    chmod +x .git/hooks/pre-commit
    echo "✅ Pre-commit hook installed"
fi

# Build the project if Package.swift exists
if [ -f "Package.swift" ]; then
    echo "🔨 Building Swift Package..."
    swift build
    echo "🧪 Running Swift Package tests..."
    swift test
fi

# Check if Xcode project builds (this might not work in Linux container)
if [ -f "tictactoe.xcodeproj/project.pbxproj" ]; then
    echo "📱 Xcode project detected"
    echo "ℹ️  Use Xcode or GitHub Actions for full iOS/macOS builds"
fi

echo ""
echo "🎉 Development environment setup complete!"
echo ""
echo "📋 Available commands:"
echo "  swift build              - Build the Swift package"
echo "  swift test               - Run tests"
echo "  swiftlint                - Run linting"
echo "  swift-format --help      - Format code"
echo ""
echo "Happy coding! 🚀"