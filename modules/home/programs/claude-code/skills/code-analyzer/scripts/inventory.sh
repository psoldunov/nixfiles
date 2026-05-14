#!/usr/bin/env bash
# Phase 1 file inventory for code-analyzer skill.
#
# Emits a JSON object to stdout summarizing the repo's file layout,
# manifests, configs, CI, and containers — everything needed to start Phase 2
# without walking the tree again.
#
# Usage:
#   ./inventory.sh [path]
#
# The argument defaults to the current working directory.
#
# Requires: bash, git (optional — falls back to find). No jq dependency —
# JSON is constructed by hand so this works on a bare Alpine/Ubuntu box.

set -euo pipefail

ROOT="${1:-$PWD}"
cd "$ROOT"

# --- helpers ---------------------------------------------------------------

# Escape a string for JSON: backslashes, quotes, control chars.
json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

# Convert a newline-separated list of paths to a JSON array of escaped strings.
# Reads from stdin.
paths_to_json_array() {
  local first=1
  printf '['
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    if [[ $first -eq 1 ]]; then
      first=0
    else
      printf ','
    fi
    printf '"%s"' "$(json_escape "$line")"
  done
  printf ']'
}

# Find files matching any of the given glob patterns, ignoring the
# usual noise directories. Uses git ls-files when the dir is a repo
# (faster and respects .gitignore), else falls back to find.
find_files() {
  local pattern
  if [[ -d .git ]] || git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    for pattern in "$@"; do
      git ls-files "$pattern" 2>/dev/null || true
    done
  else
    local -a find_args=(-type f \( -false)
    for pattern in "$@"; do
      find_args+=(-o -iname "$pattern")
    done
    find_args+=(\))
    find . \
      -path ./node_modules -prune -o \
      -path ./vendor -prune -o \
      -path ./.venv -prune -o \
      -path ./venv -prune -o \
      -path ./dist -prune -o \
      -path ./build -prune -o \
      -path ./target -prune -o \
      -path ./.next -prune -o \
      -path ./.turbo -prune -o \
      "${find_args[@]}" -print 2>/dev/null | sed 's|^\./||'
  fi
}

# --- data collection -------------------------------------------------------

GIT_SHA=""
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  GIT_SHA="$(git rev-parse --short HEAD 2>/dev/null || echo "")"
fi

FILE_COUNT=0
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  FILE_COUNT=$(git ls-files | wc -l | tr -d '[:space:]')
else
  FILE_COUNT=$(find . -type f \
    -not -path './node_modules/*' \
    -not -path './.git/*' \
    -not -path './vendor/*' \
    -not -path './dist/*' \
    -not -path './build/*' \
    2>/dev/null | wc -l | tr -d '[:space:]')
fi

MANIFESTS=$(find_files \
  'package.json' 'pnpm-workspace.yaml' 'bun.lockb' 'bun.lock' 'bunfig.toml' \
  'deno.json' 'deno.jsonc' \
  'pyproject.toml' 'setup.py' 'setup.cfg' 'requirements*.txt' 'Pipfile' 'uv.lock' \
  'go.mod' 'go.work' 'Cargo.toml' 'Gemfile' '*.gemspec' \
  'composer.json' 'pom.xml' 'build.gradle' 'build.gradle.kts' \
  'mix.exs' 'Project.toml' 'pubspec.yaml' 'Package.swift' \
  '*.csproj' '*.fsproj' '*.sln' | sort -u)

VERSION_PINS=$(find_files \
  '.nvmrc' '.node-version' '.tool-versions' '.python-version' '.ruby-version' \
  '.terraform-version' '.npmrc' '.yarnrc' '.yarnrc.yml' | sort -u)

FRAMEWORK_MARKERS=$(find_files \
  'next.config.*' 'nuxt.config.*' 'svelte.config.*' 'astro.config.*' \
  'vite.config.*' 'remix.config.*' 'angular.json' 'gatsby-config.*' \
  'manage.py' 'wsgi.py' 'asgi.py' 'config/application.rb' 'artisan' \
  'expo.json' 'app.json' | sort -u)

TOOLING=$(find_files \
  '.editorconfig' '.prettierrc*' 'prettier.config.*' 'biome.json' 'biome.jsonc' \
  '.eslintrc*' 'eslint.config.*' '.stylelintrc*' \
  'tsconfig*.json' 'jsconfig.json' \
  'ruff.toml' '.flake8' 'mypy.ini' 'pyrightconfig.json' \
  '.golangci.yml' '.golangci.toml' 'clippy.toml' '.rustfmt.toml' \
  '.rubocop.yml' 'phpstan.neon' 'psalm.xml' \
  'jest.config.*' 'vitest.config.*' 'playwright.config.*' 'cypress.config.*' \
  'pytest.ini' 'karma.conf.*' \
  '.husky' 'lefthook.yml' '.pre-commit-config.yaml' | sort -u)

CI=$(find_files \
  '.github/workflows/*.yml' '.github/workflows/*.yaml' \
  '.gitlab-ci.yml' '.circleci/config.yml' 'azure-pipelines.yml' \
  'Jenkinsfile' 'bitbucket-pipelines.yml' '.drone.yml' | sort -u)

CONTAINERS=$(find_files \
  'Dockerfile' '*.dockerfile' 'docker-compose.*' 'compose.*' \
  'vercel.json' 'netlify.toml' 'wrangler.toml' 'serverless.yml' 'sst.config.*' \
  '*.tf' '*.tfvars' 'Pulumi.yaml' | sort -u)

DOCS=$(find_files \
  'README*' 'CONTRIBUTING*' 'ARCHITECTURE*' 'CHANGELOG*' \
  'AGENTS.md' 'CLAUDE.md' '.cursorrules' '.windsurfrules' | sort -u)

# Top-level directories (depth 1)
TOP_DIRS=$(find . -maxdepth 1 -type d \
  -not -name '.' \
  -not -name '.git' \
  -not -name 'node_modules' \
  -not -name '.venv' \
  -not -name 'vendor' \
  -not -name 'dist' \
  -not -name 'build' \
  -not -name 'target' \
  2>/dev/null | sed 's|^\./||' | sort)

# --- emit json -------------------------------------------------------------

SCANNED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

printf '{'
printf '"scanned_at":"%s",' "$SCANNED_AT"
printf '"git_sha":"%s",' "$(json_escape "$GIT_SHA")"
printf '"root":"%s",' "$(json_escape "$ROOT")"
printf '"file_count":%s,' "$FILE_COUNT"

printf '"manifests":'
printf '%s' "$MANIFESTS" | paths_to_json_array
printf ','

printf '"version_pins":'
printf '%s' "$VERSION_PINS" | paths_to_json_array
printf ','

printf '"framework_markers":'
printf '%s' "$FRAMEWORK_MARKERS" | paths_to_json_array
printf ','

printf '"tooling":'
printf '%s' "$TOOLING" | paths_to_json_array
printf ','

printf '"ci":'
printf '%s' "$CI" | paths_to_json_array
printf ','

printf '"containers":'
printf '%s' "$CONTAINERS" | paths_to_json_array
printf ','

printf '"docs":'
printf '%s' "$DOCS" | paths_to_json_array
printf ','

printf '"top_level_dirs":'
printf '%s' "$TOP_DIRS" | paths_to_json_array

printf '}\n'
