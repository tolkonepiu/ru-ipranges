#!/bin/bash

set -euo pipefail

BASE_DIR=${BASE_DIR:-$(realpath "$(dirname "$0")/../../")}
IPV4_ALL="${BASE_DIR}/ipv4-all.txt"
IPV6_ALL="${BASE_DIR}/ipv6-all.txt"

: >"$IPV4_ALL"
: >"$IPV6_ALL"

find "$BASE_DIR" -type f -name "ipv4.txt" -print0 | xargs -0 cat >>"$IPV4_ALL"

find "$BASE_DIR" -type f -name "ipv6.txt" -print0 | xargs -0 cat >>"$IPV6_ALL"

sort -t . -k1,1n -k2,2n -k3,3n -k4,4n -u "$IPV4_ALL" -o "$IPV4_ALL"
sort -u -V "$IPV6_ALL" -o "$IPV6_ALL"

echo "Aggregation completed."
