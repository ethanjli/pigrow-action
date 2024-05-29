#!/bin/bash -eu

action_root="$(dirname "$(realpath "$BASH_SOURCE")")"

destination="$INPUT_DESTINATION"
if [ -z "$destination" ]; then
  destination="$(mktemp --tmpdir=/tmp raw-image.XXXXXXX)"
fi
echo "destination=$destination" >> $GITHUB_OUTPUT

case "$INPUT_MODE" in
  by)
    echo "Growing $destination by $INPUT_SIZE..."
    adjustment="+$INPUT_SIZE"
    ;;
  to)
    echo "Growing $destination to at least $INPUT_SIZE..."
    adjustment=">$INPUT_SIZE"
    ;;
  none | '')
    adjustment=""
    ;;
  *)
    echo "Error: unrecognized mode: $INPUT_MODE"
    exit 1
    ;;
esac

echo "Running pigrow.sh \"$INPUT_IMAGE\" \"$destination\" \"$adjustment\"..."
"$action_root/pigrow.sh" "$INPUT_IMAGE" "$destination" "$adjustment"
