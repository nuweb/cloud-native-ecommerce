#!/bin/bash
# Fix pnpm permission issues and install pre-commit hooks

echo "🔧 Fixing node_modules permissions..."
sudo chown -R $(whoami) node_modules/

echo "🧹 Cleaning pnpm cache and node_modules..."
rm -rf node_modules/.pnpm
pnpm store prune

echo "📦 Reinstalling dependencies..."
pnpm install

echo "🪝 Installing husky and lint-staged..."
pnpm add -D -w husky lint-staged

echo "🎣 Initializing husky..."
pnpm exec husky init

echo "✏️ Creating pre-commit hook..."
echo "pnpm exec lint-staged" > .husky/pre-commit
chmod +x .husky/pre-commit

echo "✅ Done! Pre-commit hooks are now installed."
echo ""
echo "Test with: pnpm format"
