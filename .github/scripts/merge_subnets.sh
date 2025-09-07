#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${0}")/lib/common.sh"

VENV_DIR="${ROOT_DIR}/.github/scripts/merge/venv"
MERGE_SCRIPT_PATH="${ROOT_DIR}/.github/scripts/merge/"

if [ ! -d "$VENV_DIR" ]; then
	log info "Setting up Python virtual environment..."
	python3 -m venv "$VENV_DIR"
	# shellcheck disable=SC1091
	source "$VENV_DIR/bin/activate"
	pip install --upgrade pip
	pip install -r "$MERGE_SCRIPT_PATH/requirements.txt"
	deactivate
fi

# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"

find "$ROOT_DIR" -type f \( -name "ipv4*.txt" -o -name "ipv6*.txt" \) | while read -r file; do
	if [[ "$file" == *-merged.txt ]]; then
		continue
	fi

	merged_file="${file%.txt}-merged.txt"
	python3 "$MERGE_SCRIPT_PATH/merge.py" --source "$file" >"$merged_file"
done

deactivate

log info "All files processed successfully."
