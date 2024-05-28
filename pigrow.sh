#!/bin/bash -eu
# Where indicated in this file, sections of code were copied and/or adapted from the
# https://github.com/Nature40/pimod project, which is copyrighted by its contributors and licensed
# under GPL-3.0-only. Here is the scientific citation for that project:
# @inproceedings{hoechst2020pimod,
#   author = {{Höchst}, Jonas and Penning, Alvar and Lampe, Patrick and Freisleben, Bernd},
#   title = {{PIMOD: A Tool for Configuring Single-Board Computer Operating System Images}},
#   booktitle = {{2020 IEEE Global Humanitarian Technology Conference (GHTC 2020)}},
#   address = {Seattle, USA},
#   days = {29},
#   month = oct,
#   year = {2020},
#   keywords = {Single-Board Computer; Operating System Image; System Provisioning},
# }

# unarchive_image extracts files from an archive and moves the largest file inside to a given path.
# This function was copied verbatim from the `unarchive_image` function of
# https://github.com/Nature40/pimod at
# https://github.com/Nature40/pimod/blob/2fac7b7/modules/from_remote.sh#L11-L25
unarchive_image() {
  local archive="${1}"
  local tmpfile="${2}"
  local unzip_image
  unzip_dir=$(mktemp -d --tmpdir=/tmp archive-extracted.XXXXXXX)

  7z e -bd -o"${unzip_dir}" "${archive}"

  # pick largest file, as it is most likely the image
  # shellcheck disable=SC2012
  unzip_image=$(ls -S -1 "${unzip_dir}" | head -n1)
  mv "${unzip_dir}/${unzip_image}" "${tmpfile}"
  rm -rf "${unzip_dir}"
}

# extract_image copies an image, decompressing it (as a file or from an archive) if necessary.
# This function was copied and modified from the `from_remote_fetch` function of
# https://github.com/Nature40/pimod at
# https://github.com/Nature40/pimod/blob/2fac7b7/modules/from_remote.sh#L28-L85
extract_image() {
  local input_path
  input_path="${1}"
  local destination_path
  destination_path="${2}"

  local mime
  mime=$(file -b --mime-type "${input_path}")

  case "${mime}" in
    application/octet-stream)
      # let's seriously hope it's an image..
      cp "${input_path}" "${destination_path}"
      ;;

    application/zip)
      unarchive_image "${input_path}" "${destination_path}"
      ;;

    application/x-7z-compressed)
      unarchive_image "${input_path}" "${destination_path}"
      ;;

    application/gzip)
      gunzip -c "${input_path}" > "${destination_path}"
      ;;

    application/x-gzip)
      gunzip -c "${input_path}" > "${destination_path}"
      ;;

    application/x-xz)
      unxz -c "${input_path}" > "${destination_path}"
      ;;

    *)
      echo -e "\033[0;31m### Error: Unknown MIME ${mime}\033[0m"
      return 1
      ;;
  esac
}

grow_image() {
  local adjustment
  adjustment="$1"
  local image
  image="$2"

  truncate -s "$adjustment" "$image"
  echo ", +" | sfdisk -N 2 $image

  device="$(sudo losetup -fP --show "$image")"
  sudo e2fsck -p -f "${device}p2"
  sudo resize2fs "${device}p2"
  sudo losetup -d "$device"
}

image="$1"
destination="$2"
adjustment="${3:-}"

echo "Extracting $image to $destination..."
extract_image "$image" "$destination"
if [ -z "$adjustment" ]; then
  echo ""
  return 0
fi

echo "Growing $destination: $adjustment..."
grow_image "$adjustment" "$destination"
