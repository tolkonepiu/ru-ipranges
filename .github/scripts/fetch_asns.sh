#!/bin/bash

set -euo pipefail

fetch_asn() {
    local mnt_by=$1
    local mnt_by_dir=$2

    echo "Fetching ASNs for mnt-by: $mnt_by ($(basename "$mnt_by_dir"))" >&2

    local whois_output
    if ! whois_output=$(echo "-i mnt-by $mnt_by" | nc whois.bgp.net.br 43); then
        echo "Error: Failed to fetch data for mnt-by: $mnt_by" >&2
        exit 1
    fi
    awk '/^origin:/ {print $2}' <<<"$whois_output"
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

BASE_DIR=${BASE_DIR:-$(realpath "$(dirname "$0")/../../")}

# shellcheck disable=SC2016
find "$BASE_DIR" -name "mnt-by.txt" -print0 |
    xargs -0 -n1 -P4 bash -c 'process_mnt_by_file "$0"'

echo "Script execution completed."
