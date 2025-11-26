# @kenai-platform/check-exact-packages

A CLI tool to enforce exact dependency versions (no `^` or `~` prefixes) in all `package.json` files across your repository. This helps ensure reproducible builds and prevents unexpected dependency updates.

## What it does

- **Scans all `package.json` files** in the repository (including nested ones)
- **Checks all dependency types**: `dependencies`, `devDependencies`, `peerDependencies`, and `optionalDependencies`
- **Detects non-exact versions** that use `^` (caret) or `~` (tilde) prefixes
- **Fails the check** if any non-exact versions are found
- **Provides detailed output** showing which packages in which files have non-exact versions

## Installation

Install the package from npm:

```bash
npm install --save-dev @kenai-platform/check-exact-packages
```

Or with bun:
```bash
bun add -d @kenai-platform/check-exact-packages
```

## Usage

### 1. CLI Command

After installation, you can run the check from anywhere in your repository:

**With npm/npx:**
```bash
npx @kenai-platform/check-exact-packages
```

**With bun/bunx:**
```bash
bunx @kenai-platform/check-exact-packages
```

**If installed globally:**
```bash
npm install -g @kenai-platform/check-exact-packages
check-exact-packages
```

The command will:
- Scan all `package.json` files in your repository
- Report any non-exact versions found
- Exit with code 1 if violations are found, 0 if all versions are exact

### 2. Preinstall Script (Run Without Installation)

You can run the check as a preinstall script without installing the package. This is useful for CI/CD pipelines or to enforce the check before dependencies are installed.

**In your `package.json`:**
```json
{
  "scripts": {
    "preinstall": "npx @kenai-platform/check-exact-packages"
  }
}
```

Or with bun:
```json
{
  "scripts": {
    "preinstall": "bunx @kenai-platform/check-exact-packages"
  }
}
```

**Note:** The `preinstall` script runs automatically before `npm install` or `bun install`. If non-exact versions are found, the installation will fail.

### 3. GitHub Actions Workflow

Add a GitHub Actions workflow to automatically check for exact versions on pull requests and pushes:

Create `.github/workflows/check-exact-versions.yml`:

```yaml
name: Check Exact Versions

on:
  pull_request:
    paths:
      - '**/package.json'
  push:
    branches: [main, master]
    paths:
      - '**/package.json'

jobs:
  check-versions:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
      
      - name: Run check-exact-packages
        run: npx @kenai-platform/check-exact-packages
```

### 4. Pre-commit Hook

#### Using pre-commit.com

Add this to your `.pre-commit-config.yaml`:

```yaml
repos:
  - repo: https://github.com/Spookfish-ai/check-exact-packages
    rev: v1.0.0  # Use the latest version tag
    hooks:
      - id: check-exact-packages
```

Then install and run:
```bash
pre-commit install
pre-commit run check-exact-packages --all-files
```

The hook will automatically run before each commit.

#### Using Husky

If you're using Husky in your project:

1. **Install the package:**
   ```bash
   npm install --save-dev @kenai-platform/check-exact-packages
   ```

2. **Add to your `.husky/pre-commit` file:**
   ```bash
   #!/usr/bin/env sh
   . "$(dirname -- "$0")/_/husky.sh"
   
   npx check-exact-packages || exit 1
   ```

   Or with bun:
   ```bash
   #!/usr/bin/env sh
   . "$(dirname -- "$0")/_/husky.sh"
   
   bunx @kenai-platform/check-exact-packages || exit 1
   ```

The hook will automatically run before each commit.

## Prerequisites

- **jq**: Required to parse JSON files
  - Pre-installed on GitHub Actions `ubuntu-latest` runners
  - For local use, install via: `brew install jq` (macOS) or `apt-get install jq` (Linux)
- **git**: Required to find `package.json` files (uses `git ls-files`)
- **bash**: Required to run the script

## Example Output

When non-exact versions are found:

```
package.json has packages with non-exact versions:
  • express: ^4.18.0
  • lodash: ~4.17.21

Error: Use exact versions (no ^ or ~) in package.json files
```

When all versions are exact:

```
✓ All package.json files use exact versions
```

## Publishing

This package is automatically published to npm when:
- Changes are pushed to `main` branch that modify `check-exact-packages.sh` or `bin/check-exact-packages`
- The version in `package.json` is manually updated

The publish workflow (`publish.yml`) will:
- Automatically bump the patch version if the script changes
- Publish to `@kenai-platform/check-exact-packages` on npm
- Create a git tag for the new version

**Note:** The workflow requires an `NPM_TOKEN` secret to be configured in GitHub Actions with publish permissions for the `@kenai-platform` scope.

## Development

To contribute or modify this package:

1. Clone the repository
2. Make your changes
3. Update the version in `package.json` if needed
4. Test locally: `./check-exact-packages.sh` or `./bin/check-exact-packages`
5. Commit and push - the publish workflow will handle publishing
