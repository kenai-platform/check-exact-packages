#!/bin/bash
# Self-check for bin/check-exact-packages. Builds a throwaway git repo per case
# (the tool scans `git ls-files`) and asserts the exit code.
set -u

CHECKER="$(cd "$(dirname "$0")/.." && pwd)/bin/check-exact-packages"
fails=0

# assert <expected-exit> <name> <package.json body>
assert() {
  local expected=$1 name=$2 body=$3
  local dir
  dir=$(mktemp -d)
  printf '%s' "$body" > "$dir/package.json"
  git -C "$dir" init -q && git -C "$dir" add -A
  local out
  out=$(cd "$dir" && "$CHECKER" 2>&1)
  local actual=$?
  rm -rf "$dir"

  if [ "$actual" -ne "$expected" ]; then
    echo "FAIL: $name (expected exit $expected, got $actual)"
    echo "$out" | sed 's/^/      /'
    fails=1
  else
    echo "ok:   $name"
  fi
}

# --- must fail (0 = pass, 1 = fail) ---
assert 1 'dist-tag preview'   '{"dependencies":{"@serwist/turbopack":"preview"}}'
assert 1 'dist-tag latest'    '{"dependencies":{"a":"latest"}}'
assert 1 'caret'              '{"dependencies":{"a":"^1.0.0"}}'
assert 1 'tilde'              '{"devDependencies":{"a":"~1.0.0"}}'
assert 1 'wildcard'           '{"dependencies":{"a":"*"}}'
assert 1 'empty string'       '{"dependencies":{"a":""}}'
assert 1 'gte range'          '{"dependencies":{"a":">=1.0.0"}}'
assert 1 'x range'            '{"dependencies":{"a":"1.x"}}'
assert 1 'or range'           '{"dependencies":{"a":"1 || 2"}}'
assert 1 'git url'            '{"dependencies":{"a":"git+https://x/y.git"}}'
assert 1 'npm alias'          '{"dependencies":{"a":"npm:b@^1.0.0"}}'
assert 1 'optionalDeps'       '{"optionalDependencies":{"a":"next"}}'

# --- must pass ---
assert 0 'exact semver'       '{"dependencies":{"a":"1.0.0"}}'
assert 0 'prerelease'         '{"dependencies":{"serwist":"10.0.0-preview.14"}}'
assert 0 'build metadata'     '{"dependencies":{"a":"1.0.0+build.1"}}'
assert 0 'catalog bare'       '{"dependencies":{"a":"catalog:"}}'
assert 0 'catalog named'      '{"dependencies":{"a":"catalog:react"}}'
assert 0 'workspace star'     '{"dependencies":{"a":"workspace:*"}}'
assert 0 'workspace version'  '{"dependencies":{"a":"workspace:1.0.0"}}'
assert 0 'peer ranges'        '{"peerDependencies":{"typescript":">=5","zod":">=4","next":">=16.0.0-0","react":">=18","react-dom":">=18"}}'

# ENG-121 trap 2: same key in devDependencies and peerDependencies. The bad
# dev value must not be masked by the (ignored) peer value.
assert 1 'dup key not masked' '{"devDependencies":{"next":"preview"},"peerDependencies":{"next":">=16.0.0-0"}}'

exit $fails
