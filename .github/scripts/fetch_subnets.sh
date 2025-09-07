#!/bin/bash

set -euo pipefail

fetch_subnets() {
	local asn=$1
	local asn_dir=$2

	echo "Fetching subnets for ASN: $asn ($(basename "$asn_dir"))" >&2

	local base_url="https://raw.githubusercontent.com/ipverse/asn-ip/master/as/${asn#AS}"
	local all_subnets
	all_subnets=$(mktemp)

	curl -s -f "$base_url/ipv4-aggregated.txt" | grep -v '^#' | grep -v '^$' >>"$all_subnets" 2>/dev/null
	curl -s -f "$base_url/ipv6-aggregated.txt" | grep -v '^#' | grep -v '^$' >>"$all_subnets" 2>/dev/null

	grep -v '^$' "$all_subnets" | sort -u -V
	rm -f "$all_subnets"
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

		grep -v ':' <<<"$whois_result" >>"$ipv4_tmp" || true
		grep ':' <<<"$whois_result" >>"$ipv6_tmp" || true
	done <"$asn_file"

	grep -v '^$' "$ipv4_tmp" | sort -u -t. -k1,1n -k2,2n -k3,3n -k4,4n >"$ipv4_file"
	grep -v '^$' "$ipv6_tmp" |
		python3 -c '
import sys, ipaddress

for s in sys.stdin:
    s = s.strip()
    if not s:
        continue
    net = ipaddress.ip_network(s, strict=False)
    print(net.network_address.exploded, net.prefixlen, s)
' |
		sort -k1,1 -k2,2n |
		awk '{print $3}' \
			>"$ipv6_file"
}

export -f fetch_subnets process_asn_file

BASE_DIR=${BASE_DIR:-$(realpath "$(dirname "$0")/../../")}

# shellcheck disable=SC2016
find "$BASE_DIR" -name "asn.txt" -print0 |
	xargs -0 -n1 -P4 bash -c 'process_asn_file "$0"'

echo "Script execution completed."
