# Pre-commit Hooks Setup with Husky and Lint-Staged

This guide sets up automatic formatting and linting before each commit.

## What's Configured

- **Prettier**: Formats code and removes trailing whitespace
- **ESLint**: Lints and auto-fixes issues
- **Husky**: Git hooks manager
- **Lint-staged**: Runs commands only on staged files

## Installation

```bash
# Install dependencies
pnpm add -D husky lint-staged

# Initialize husky
pnpm exec husky init

# Install git hooks
pnpm install
```

## Configuration Files

### `.prettierrc`

```json
{
  "singleQuote": true,
  "trailingComma": "es5",
  "tabWidth": 2,
  "semi": true,
  "printWidth": 100,
  "endOfLine": "lf"
}
```

### `package.json` - Scripts

```json
{
  "scripts": {
    "format": "prettier --write \"**/*.{ts,tsx,js,jsx,json,md,html,css,scss}\"",
    "format:check": "prettier --check \"**/*.{ts,tsx,js,jsx,json,md,html,css,scss}\"",
    "lint": "nx run-many -t lint",
    "prepare": "husky"
  }
}
```

### `package.json` - Lint-staged config

```json
{
  "lint-staged": {
    "*.{ts,tsx,js,jsx}": ["eslint --fix", "prettier --write"],
    "*.{json,md,html,css,scss}": ["prettier --write"]
  }
}
```

## Manual Commands

```bash
# Format all files manually
pnpm format

# Check formatting without modifying files
pnpm format:check

# Lint all projects
pnpm lint
```

## How It Works

When you commit:

1. Husky intercepts the commit
2. Lint-staged runs on staged files only
3. ESLint fixes issues
4. Prettier formats code and removes trailing whitespace
5. Files are automatically re-staged
6. Commit proceeds

## Bypass (Not Recommended)

```bash
# Skip pre-commit hooks (emergency only)
git commit --no-verify -m "message"
```

## Files Modified

- `package.json` - Added scripts and lint-staged config
- `.prettierrc` - Enhanced formatting rules
- `.prettierignore` - Files to ignore
- `.husky/pre-commit` - Git pre-commit hook
