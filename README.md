# @kenai-platform/check-exact-packages

A CLI tool to enforce exact dependency versions in all `package.json` files across your repository. This helps ensure reproducible builds and prevents unexpected dependency updates.

## What it does

- **Scans all `package.json` files** in the repository (including nested ones)
- **Checks `dependencies`, `devDependencies` and `optionalDependencies`**, each section separately
- **Skips `peerDependencies`**, where ranges like `>=5` are correct
- **Fails the check** if any spec is not pinned
- **Provides detailed output** naming the file, the section and the offending spec

### What passes

| Spec | Example |
|---|---|
| Exact semver | `1.2.3` |
| Exact prerelease / build metadata | `10.0.0-preview.14`, `1.0.0+build.1` |
| Catalog protocol | `catalog:`, `catalog:react` |
| Workspace protocol | `workspace:*`, `workspace:1.0.0` |

Everything else fails — this is an allow-list, not a blocklist. That includes
`^1.0.0`, `~1.0.0`, dist-tags (`preview`, `latest`, `next`, `canary`), wildcards
(`*`, `""`), ranges (`>=1.0.0`, `1.x`, `1 || 2`), partial versions (`8.5`), and
git / URL / `npm:` alias specs.

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
  - repo: https://github.com/kenai-platform/check-exact-packages
    rev: v2.0.0  # Use the latest version tag
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

## Releasing

Releases are automated with [release-please](https://github.com/googleapis/release-please). **Nobody edits the version by hand and nobody runs `npm publish`.**

The loop:

1. Land a [Conventional Commit](https://www.conventionalcommits.org/) on `main` — `fix:`, `feat:`, or anything with `!`/`BREAKING CHANGE:` for a major.
2. release-please opens (or updates) a **release PR** with the next version and a generated `CHANGELOG.md`.
3. Merge that release PR when you want to ship. That tags the commit, cuts a GitHub Release, and publishes to npm.

Which commit prefix moves which number:

| Prefix | Bump | Example |
|---|---|---|
| `fix:` | patch | `fix: handle empty dependency blocks` |
| `feat:` | minor | `feat: report the dependency section on failure` |
| `feat!:` / `BREAKING CHANGE:` | major | `feat!: reject dist-tags and ranges` |
| `chore:`, `docs:`, `ci:`, `refactor:` | none | housekeeping, no release |

Commits that don't parse as Conventional Commits are ignored — no bump, silently. Squash-merge PRs so the PR title becomes the commit subject, and keep that title conventional.

Every published version carries [npm provenance](https://docs.npmjs.com/generating-provenance-statements), so the tarball on npm is cryptographically linked to the commit and workflow run that built it.

### One-time setup

Publishing uses npm [trusted publishing](https://docs.npmjs.com/trusted-publishers) (OIDC) rather than a long-lived token — there is no `NPM_TOKEN` secret to leak or rotate. On npmjs.com, under the package's **Settings → Trusted Publisher**, point it at:

| Field | Value |
|---|---|
| Repository | `kenai-platform/check-exact-packages` |
| Workflow | `release.yml` |

If you rename `.github/workflows/release.yml`, update it there too or publishing will start failing with an auth error.

## Development

```bash
git clone https://github.com/kenai-platform/check-exact-packages.git
cd check-exact-packages
npm test            # runs test/run.sh
./bin/check-exact-packages   # run the checker against this repo
```

`test/run.sh` builds a throwaway git repo per case (the tool scans `git ls-files`) and asserts the exit code. Add a case there for any spec form you change the handling of. CI runs it on Ubuntu and macOS — the stock bash on macOS is 3.2, so keep the script portable.
