# PiGrow GitHub Action

GitHub action to expand a Raspberry Pi SD card image

This action is the inverse of [ethanjli/pishrink-action](https://github.com/ethanjli/pishrink-action).

## Basic Usage Examples

### Grow an image to a size

```yaml
- name: Download an example image
  run: wget https://downloads.raspberrypi.com/raspios_lite_arm64/images/raspios_lite_arm64-2024-03-15/2024-03-15-raspios-bookworm-arm64-lite.img.xz

- name: Grow the image
  uses: ethanjli/pigrow-action@v0.1.0
  with:
    image: 2024-03-15-raspios-bookworm-arm64-lite.img.xz
    destination: 2024-03-15-raspios-bookworm-arm64-lite.img
    mode: to
    size: 8G

- name: Upload the image to Job Artifacts
  uses: actions/upload-artifact@v4
  with:
    name: grown-image
    path: 2024-03-15-raspios-bookworm-arm64-lite.img
    if-no-files-found: error
    overwrite: true
```

### Grow an image by an amount

```yaml
- name: Download an example image
  run: wget https://downloads.raspberrypi.com/raspios_lite_arm64/images/raspios_lite_arm64-2024-03-15/2024-03-15-raspios-bookworm-arm64-lite.img.xz

- name: Grow the image
  uses: ethanjli/pigrow-action@v0.1.0
  with:
    image: 2024-03-15-raspios-bookworm-arm64-lite.img.xz
    destination: 2024-03-15-raspios-bookworm-arm64-lite.img
    mode: by
    size: 1G

- name: Upload the image to Job Artifacts
  uses: actions/upload-artifact@v4
  with:
    name: grown-image
    path: 2024-03-15-raspios-bookworm-arm64-lite.img
    if-no-files-found: error
    overwrite: true
```

### Extract but don't grow an image

```yaml
- name: Download an example image
  run: wget https://downloads.raspberrypi.com/raspios_lite_arm64/images/raspios_lite_arm64-2024-03-15/2024-03-15-raspios-bookworm-arm64-lite.img.xz

- name: Extract the image
  uses: ethanjli/pigrow-action@v0.1.0
  with:
    image: 2024-03-15-raspios-bookworm-arm64-lite.img.xz
    destination: 2024-03-15-raspios-bookworm-arm64-lite.img

- name: Upload the image to Job Artifacts
  uses: actions/upload-artifact@v4
  with:
    name: extracted-image
    path: 2024-03-15-raspios-bookworm-arm64-lite.img
    if-no-files-found: error
    overwrite: true
```

## `systemd-nspawn` Usage Example

This example job grows the image before running commands in a lightweight namespace container
(using `systemd-nspawn`) to generate a custom image, then shrinks it before uploading as an artifact
on the GitHub Actions job:

```yaml
jobs:
  build:
    name: Build image
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Download a base image
        run: wget https://downloads.raspberrypi.com/raspios_lite_arm64/images/raspios_lite_arm64-2024-03-15/2024-03-15-raspios-bookworm-arm64-lite.img.xz

      - name: Grow the image
        uses: ethanjli/pigrow-action@v0.1.0
        with:
          image: 2024-03-15-raspios-bookworm-arm64-lite.img.xz
          destination: cowsay-image.img
          mode: to
          size: 8G

      - name: Build the image
        run: |
          # Install containerization dependencies:
          sudo apt-get install systemd-container qemu-user-static binfmt-support

          # Mount the image:
          device="$(losetup -fP --show cowsay-image.img)"

          # Run commands in the container:
          sudo systemd-nspawn --image "${device}p2" bash -c "\
            apt-get update
            apt-get install -y cowsay
            /usr/games/cowsay "I am running in a light-weight namespace container!"
          "

          # Unmount the image:
          sudo losetup -d "$device"

      - name: Shrink the image
        uses: ethanjli/pishrink-action@v0.1.1
        with:
          image: cowsay-image.img
          compress: gzip
          compress-parallel: true

      - name: Upload the image to Job Artifacts
        uses: actions/upload-artifact@v4
        with:
          name: rpi-cowsay-arm64-latest
          path: cowsay-image.img.gz
          if-no-files-found: error
          retention-days: 0
          compression-level: 0
          overwrite: true
```

## Usage Options

Inputs:

| Input         | Allowed values     | Required?                    | Description                                                       |
|---------------|--------------------|------------------------------|-------------------------------------------------------------------|
| `image`       | file path          | yes                          | Path of the image to grow.                                        |
| `destination` | file path          | no (default random tempfile) | Path to write the grown image to.                                 |
| `mode`        | `none`, `by`, `to` | no (default `none`)          | Grow the image by the size (`by`) or to at least the size (`to`). |
| `size`        | size               | no (default `0`)             | Size adjustment.                                                  |

- The `size` input may be an integer, a unit, or an integer followed by a unit (with no space separating them):

  - Allowed units are: KB (kilobyte), K (kibibyte), MB (megabyte), M (mebibyte), G (gigabyte), GB (gibibyte), and so on for T, P, E, Z, Y
  - For example, `1024`, `K`, and `1K` all represent a size of 1024 bytes and are interchangeable.
  - For example, `GB` and `1GB` both represent a size of 1 gigabyte and are interchangeable.

Outputs:

- `destination` is the path of the grown image. If no destination path was specified in the input
  to this action, a random path will be generated in `/tmp` as the path of the grown image.

## Credits

This repository includes a modified copy of code snippets from the `from_remote.sh` module script of
[Nature40/pimod](https://github.com/Nature40/pimod), published under the GPL-3.0 License; as a
result, this repository is also released under GPL-3.0-only. Here is the citation for the pimod
project's [scientific paper](https://jonashoechst.de/assets/papers/hoechst2020pimod.pdf):

```bibtex
@inproceedings{hoechst2020pimod,
  author = {{Höchst}, Jonas and Penning, Alvar and Lampe, Patrick and Freisleben, Bernd},
  title = {{PIMOD: A Tool for Configuring Single-Board Computer Operating System Images}},
  booktitle = {{2020 IEEE Global Humanitarian Technology Conference (GHTC 2020)}},
  address = {Seattle, USA},
  days = {29},
  month = oct,
  year = {2020},
  keywords = {Single-Board Computer; Operating System Image; System Provisioning},
}
```
