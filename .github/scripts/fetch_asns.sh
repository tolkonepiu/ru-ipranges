#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${0}")/lib/common.sh"

fetch_asn() {
	local mnt_by=$1
	local mnt_by_dir=$2

	log info "Fetching ASNs for mnt-by: $mnt_by ($(basename "$mnt_by_dir"))" >&2

	local whois_servers=(
		"riswhois.ripe.net"
		"whois.radb.net"
		"rr.ntt.net"
		"whois.rogerstelecom.net"
		"whois.bgp.net.br"
	)

	local asns
	asns=$(mktemp)

	for server in "${whois_servers[@]}"; do
		local whois_output
		if whois_output=$(whois -h "$server" -- "-i mnt-by $mnt_by" 2>/dev/null); then
			awk '/^origin:/ {print $2}' <<<"$whois_output" >>"$asns"
		else
			log error "Failed to fetch data from $server for mnt-by: $mnt_by"
		fi
	done

	sort -u -V "$asns"
}

process_mnt_by_file() {
	local mnt_by_file=$1
	local mnt_by_dir asn_file

	mnt_by_dir=$(dirname "$mnt_by_file")
	asn_file="$mnt_by_dir/asn.txt"

	local asn_tmp
	asn_tmp=$(mktemp)

	while read -r mnt_by || [[ -n $mnt_by ]]; do
		[[ -z $mnt_by ]] && continue

		fetch_asn "$mnt_by" "$mnt_by_dir" >>"$asn_tmp"
	done <"$mnt_by_file"

	sort -u -V "$asn_tmp" >"$asn_file"
}

export -f fetch_asn process_mnt_by_file

# shellcheck disable=SC2016
find "$ROOT_DIR" -name "mnt-by.txt" -print0 |
	xargs -0 -n1 -P4 bash -c 'process_mnt_by_file "$0"'

log info "Script execution completed."
