#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${0}")/lib/common.sh"

fetch_subnets() {
	local asn=$1
	local asn_dir=$2
	local subnets
	subnets=$(mktemp)

	log info "Fetching subnets for ASN: $asn ($(basename "$asn_dir"))" >&2

	local base_url="https://raw.githubusercontent.com/ipverse/asn-ip/master/as/${asn#AS}"

	curl -s -f "$base_url/ipv4-aggregated.txt" | grep -v '^#' | grep -v '^$' >>"$subnets" 2>/dev/null
	curl -s -f "$base_url/ipv6-aggregated.txt" | grep -v '^#' | grep -v '^$' >>"$subnets" 2>/dev/null

	grep -v '^$' "$subnets"
	rm -f "$subnets"
}

process_asn_file() {
	local asn_file=$1
	local asn_dir ipv4_file ipv6_file

	asn_dir=$(dirname "$asn_file")
	ipv4_file="$asn_dir/ipv4.txt"
	ipv6_file="$asn_dir/ipv6.txt"

	local ipv4_tmp ipv6_tmp
	ipv4_tmp=$(mktemp)
	ipv6_tmp=$(mktemp)

	while read -r asn; do
		[[ -z $asn ]] && continue

		local whois_result
		whois_result=$(fetch_subnets "$asn" "$asn_dir")
		if [[ -n "$whois_result" ]]; then
			grep -v ':' <<<"$whois_result" >>"$ipv4_tmp" || true
			grep ':' <<<"$whois_result" >>"$ipv6_tmp" || true
		fi
	done <"$asn_file"

	sort_ipv4 "$ipv4_tmp" "$ipv4_file"
	sort_ipv6 "$ipv6_tmp" "$ipv6_file"
}

export -f fetch_subnets process_asn_file

# shellcheck disable=SC2016
find "$ROOT_DIR" -name "asn.txt" -print0 |
	xargs -0 -n1 -P4 bash -c 'process_asn_file "$0"'

log info "Script execution completed."
