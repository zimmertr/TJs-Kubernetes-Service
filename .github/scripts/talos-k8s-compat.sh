#!/usr/bin/env bash
# Checks every Talos and Kubernetes version pair this repo would deploy (the
# variable defaults, and each tfvars file's overrides) against the support
# range Talos publishes in its source, and prints a Markdown report. Exits 1
# when any pair is unsupported.
set -euo pipefail

pick() { # pick <key> <file>: the first `key = "vX.Y.Z"` or `optional(string, "vX.Y.Z")` value in file
  grep -oE "(^|[^_a-z])$1 *= *(optional\(string, *)?\"v[0-9]+\.[0-9]+\.[0-9]+\"" "$2" | head -n1 | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' || true
}

default_talos=$(pick talos_version variables.tf)
default_k8s=$(pick kubernetes_version variables.tf)
status=0
echo "| Source | Talos | Kubernetes | Talos supports | Result |"
echo "| --- | --- | --- | --- | --- |"
for source in variables.tf vars/*.tfvars; do
  talos=$(pick talos_version "$source"); talos=${talos:-$default_talos}
  k8s=$(pick kubernetes_version "$source"); k8s=${k8s:-$default_k8s}
  minor=$(echo "$talos" | sed -E 's/^v([0-9]+)\.([0-9]+)\..*/\1\2/')
  url="https://raw.githubusercontent.com/siderolabs/talos/$talos/pkg/machinery/compatibility/talos$minor/talos$minor.go"
  if ! matrix=$(curl -fsSL "$url"); then
    echo "| \`$source\` | $talos | $k8s | unknown | ❌ no support matrix at $talos |"; status=1; continue
  fi
  min=$(echo "$matrix" | grep -oE 'MinimumKubernetesVersion = semver.MustParse\("[^"]+"\)' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
  max=$(echo "$matrix" | grep -oE 'MaximumKubernetesVersion = semver.MustParse\("[^"]+"\)' | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
  v=${k8s#v}
  if [ "$(printf '%s\n' "$min" "$v" | sort -V | head -n1)" = "$min" ] && [ "$(printf '%s\n' "$v" "$max" | sort -V | tail -n1)" = "$max" ]; then
    result="✅ compatible"
  else
    result="❌ not supported"; status=1
  fi
  echo "| \`$source\` | $talos | $k8s | $min – $max | $result |"
done
exit $status
