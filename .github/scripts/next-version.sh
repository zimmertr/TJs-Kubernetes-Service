#!/usr/bin/env bash
# Prints the version a squash merge titled "$1" would release, counted from the
# latest v* tag. The PR title is the squash commit title, so it alone decides
# the bump: "!" before the colon is major, feat is minor, anything else patch.
set -euo pipefail

title=$1
latest=$(git tag --list 'v*' --sort=-v:refname | head -n1)
latest=${latest:-v0.0.0}
IFS=. read -r major minor patch <<<"${latest#v}"

re_major='^[a-z]+(\([^)]+\))?!:'
re_minor='^feat(\([^)]+\))?:'
if [[ $title =~ $re_major ]]; then
  echo "v$((major + 1)).0.0"
elif [[ $title =~ $re_minor ]]; then
  echo "v${major}.$((minor + 1)).0"
else
  echo "v${major}.${minor}.$((patch + 1))"
fi
