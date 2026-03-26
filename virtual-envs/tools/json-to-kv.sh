#!/bin/sh
# Flatten JSON to a single semicolon-separated line: key=value;key=value;...
# Only leaf values of type string or number are emitted (objects/arrays are
# walked; booleans and null are skipped).
#
# Usage:
#   json-to-kv.sh [file.json]   # read file; omit to read stdin
#
# Requires: jq
#
# Edge cases (documented):
#   - Root scalar (e.g. 42 or "hi"): key is empty, output starts with "=42" or "=hi".
#   - Strings containing "=" or ";": output is unescaped; consumers cannot split naively.
set -e

if ! command -v jq >/dev/null 2>&1; then
  echo "json-to-kv.sh: jq is required in PATH." >&2
  exit 1
fi

# Root scalars are not listed by `paths`; handle them so output is =value (empty key).
# Dot-separated paths; array indices appear as numeric segments (e.g. items.0.name).
JQ_FILTER='(
  if (type == "string" or type == "number") then
    [ "=\(if type == "number" then tostring else . end)" ]
  else
    [
      paths as $p
      | getpath($p) as $v
      | select(($v | type) == "string" or ($v | type) == "number")
      | ($p | map(tostring) | join(".")) as $key
      | "\($key)=\($v | if type == "number" then tostring else . end)"
    ]
  end
) | join(";")'

if [ "$#" -ge 1 ]; then
  jq -r "$JQ_FILTER" "$1"
else
  jq -r "$JQ_FILTER"
fi
