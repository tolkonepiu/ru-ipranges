#!/usr/bin/env bash
set -Eeuo pipefail

export LOG_LEVEL="debug"
export ROOT_DIR=${BASE_DIR:-$(git rev-parse --show-toplevel)}

function log() {
	local level="${1:-info}"
	shift

	local -A level_priority=(
		[debug]=1
		[info]=2
		[warn]=3
		[error]=4
	)

	local current_priority=${level_priority[$level]:-2}

	local configured_level=${LOG_LEVEL:-info}
	local configured_priority=${level_priority[$configured_level]:-2}

	if ((current_priority < configured_priority)); then
		return
	fi

	local -A colors=(
		[debug]="\033[1m\033[38;5;63m"  # Blue
		[info]="\033[1m\033[38;5;87m"   # Cyan
		[warn]="\033[1m\033[38;5;192m"  # Yellow
		[error]="\033[1m\033[38;5;198m" # Red
	)

	local color="${colors[$level]:-${colors[info]}}"
	local msg="$1"
	shift

	local data=
	if [[ $# -gt 0 ]]; then
		for item in "$@"; do
			if [[ ${item} == *=* ]]; then
				data+="\033[1m\033[38;5;236m${item%%=*}=\033[0m\"${item#*=}\" "
			else
				data+="${item} "
			fi
		done
	fi

	local output_stream="/dev/stdout"
	if [[ $level == "error" ]]; then
		output_stream="/dev/stderr"
	fi

	printf "%s %b%s%b %s %b\n" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
		"${color}" "${level^^}" "\033[0m" "${msg}" "${data}" >"${output_stream}"

	if [[ $level == "error" ]]; then
		exit 1
	fi
}

export -f log

sort_cidrs() {
	local input_file="$1"
	local output_file="$2"

	if [[ -z "$input_file" || -z "$output_file" ]]; then
		echo "Usage: sort_ipv4 <input_file> <output_file>" >&2
		return 1
	fi

	cat "$input_file" |
		python3 -c '
import sys, ipaddress
nets = []
for line in sys.stdin:
    try:
        nets.append(ipaddress.ip_network(line.strip(), strict=False))
    except ValueError:
        pass
for net in sorted(set(nets), key=lambda n: (n.version, int(n.network_address), n.prefixlen)):
    print(net)
' >"$output_file"
}

export -f sort_cidrs
