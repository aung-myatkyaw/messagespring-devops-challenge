# shellcheck shell=bash
# set_value <file> <key-prefix> <value>
#
# Replaces the value on the one line that starts with <key-prefix> (indentation
# and key included, e.g. "  tag: "), and fails unless exactly one line matches.
# Line-based on purpose: yq -i rewrites the whole file and drops its blank
# lines, which makes every automated change a noisy diff.
set_value() {
  local file=$1 key=$2 value=$3
  if [[ $(grep -cE "^${key}" "$file") != 1 ]]; then
    echo "expected exactly one '${key}' line in $file" >&2
    exit 1
  fi
  sed -E "s|^(${key}).*|\1${value}|" "$file" >"$file.tmp" && mv "$file.tmp" "$file"
}
