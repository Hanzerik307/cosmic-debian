#!/usr/bin/env bash

# File paths for output
BUILD_DEPS_FILE="all_build_dependencies.txt"
RUNTIME_DEPS_FILE="all_runtime_dependencies.txt"

# Clear previous outputs
> "$BUILD_DEPS_FILE"
> "$RUNTIME_DEPS_FILE"

echo "Scanning cosmic-epoch for debian/control files..."

# Find all debian/control files under the current directory
while IFS= read -r control_file; do
    echo "Processing: $control_file"

    # 1. Extract, clean, and map Build-Depends block
    sed -n '/^Build-Depends:/,/^[A-Z]/p' "$control_file" | \
        sed '1d;$d' | \
        tr -d ' \t' | \
        tr ',' '\n' | \
        sed 's/(.*)//g' | \
        grep -v '^[[:space:]]*$' | \
        grep -v '\${.*}' | \
        while IFS= read -r dep; do
            echo "$dep ($control_file)" >> "$BUILD_DEPS_FILE"
        done

    # 2. Extract, clean, and map Depends block
    sed -n '/^Depends:/,/^[A-Z]/p' "$control_file" | \
        sed '1d;$d' | \
        tr -d ' \t' | \
        tr ',' '\n' | \
        sed 's/(.*)//g' | \
        grep -v '^[[:space:]]*$' | \
        grep -v '\${.*}' | \
        while IFS= read -r dep; do
            echo "$dep ($control_file)" >> "$RUNTIME_DEPS_FILE"
        done

done < <(find . -type f -path "*/debian/control")

# Sort and deduplicate the final paired lists
clean_dependencies() {
    local file="$1"
    if [ -f "$file" ]; then
        sort -u "$file" > "${file}.tmp"
        mv "${file}.tmp" "$file"
    fi
}

clean_dependencies "$BUILD_DEPS_FILE"
clean_dependencies "$RUNTIME_DEPS_FILE"

echo "--------------------------------------------------"
echo "Done! Summary generated:"
echo "-> Build tools saved to: $BUILD_DEPS_FILE ($(wc -l < "$BUILD_DEPS_FILE") packages)"
echo "-> Runtime tools saved to: $RUNTIME_DEPS_FILE ($(wc -l < "$RUNTIME_DEPS_FILE") packages)"

