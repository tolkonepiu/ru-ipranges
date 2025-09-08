#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${0}")/lib/common.sh"

ipv4_tmp=$(mktemp)
ipv6_tmp=$(mktemp)

ipv4_all="${ROOT_DIR}/ipv4-all.txt"
ipv6_all="${ROOT_DIR}/ipv6-all.txt"

: >"$ipv4_all"
: >"$ipv6_all"

find "$ROOT_DIR" -type f -name "ipv4.txt" -print0 | xargs -0 cat >>"$ipv4_tmp"

find "$ROOT_DIR" -type f -name "ipv6.txt" -print0 | xargs -0 cat >>"$ipv6_tmp"

sort_cidrs "$ipv4_tmp" "$ipv4_all"
sort_cidrs "$ipv6_tmp" "$ipv6_all"

log info "Aggregation completed."
