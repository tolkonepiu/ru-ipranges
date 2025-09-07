#!/bin/bash

set -euo pipefail

fetch_subnets() {
	local asn=$1
	local asn_dir=$2

	echo "Fetching subnets for ASN: $asn ($(basename "$asn_dir"))" >&2

	local whois_servers=(
		"riswhois.ripe.net"
		"whois.radb.net"
		"rr.ntt.net"
		"whois.rogerstelecom.net"
		"whois.bgp.net.br"
	)

	local all_subnets
	all_subnets=$(mktemp)

	for server in "${whois_servers[@]}"; do
		local whois_output
		if whois_output=$(whois -h "$server" -- "-i origin $asn" 2>/dev/null); then
			awk '
            /^route/ {
                ip = $2
                if (ip ~ /\//) {
                    print ip
                } else if (ip ~ /:/) {
                    print ip "/128"  # IPv6
                } else {
                    print ip "/32"   # IPv4
                }
            }' <<<"$whois_output" >>"$all_subnets"
		else
			echo "Error: Failed to fetch data from $server for ASN: $asn" >&2
			exit 1
		fi
	done

	if [[ -s "$all_subnets" ]]; then
		sort -u -V "$all_subnets"
		rm -f "$all_subnets"
	else
		echo "Error: No data found for ASN: $asn from any server" >&2
		rm -f "$all_subnets"
		exit 1
	fi
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

	sort -u -t. -k1,1n -k2,2n -k3,3n -k4,4n "$ipv4_tmp" >"$ipv4_file"
	sort -u -V "$ipv6_tmp" >"$ipv6_file"
}

export -f fetch_subnets process_asn_file

BASE_DIR=${BASE_DIR:-$(realpath "$(dirname "$0")/../../")}

# shellcheck disable=SC2016
find "$BASE_DIR" -name "asn.txt" -print0 |
	xargs -0 -n1 -P4 bash -c 'process_asn_file "$0"'

echo "Script execution completed."
