#!/bin/bash

set -euo pipefail

BASE_DIR=${BASE_DIR:-$(realpath "$(dirname "$0")/../../")}

VENV_DIR="${BASE_DIR}/.github/scripts/merge/venv"
MERGE_SCRIPT_PATH="${BASE_DIR}/.github/scripts/merge/"

if [ ! -d "$VENV_DIR" ]; then
    echo "Setting up Python virtual environment..."
    python3 -m venv "$VENV_DIR"
    # shellcheck disable=SC1091
    source "$VENV_DIR/bin/activate"
    pip install --upgrade pip
    pip install -r "$MERGE_SCRIPT_PATH/requirements.txt"
    deactivate
fi

# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"

find "$BASE_DIR" -type f \( -name "ipv4*.txt" -o -name "ipv6*.txt" \) | while read -r file; do
    if [[ "$file" == *-merged.txt ]]; then
        continue
    fi

    merged_file="${file%.txt}-merged.txt"
    python3 "$MERGE_SCRIPT_PATH/merge.py" --source "$file" >"$merged_file"
done

deactivate

echo "All files processed successfully."
