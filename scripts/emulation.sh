# Ensure the script fails if an error occurs.

set -e

# Set constants.

DETAILED_LOGFILE=joseph_leskey_lab0_log.txt
OS_IMAGE_LOCATION="http://download.opensuse.org/ports/riscv/tumbleweed/images/"
OS_IMAGE_NAME="openSUSE-Tumbleweed-RISC-V-JeOS-efi.riscv64-2024.09.02-Build1.47"
OS_IMAGE_EXTENSION=".raw"
OS_IMAGE_ARCHIVE_EXTENSION="$OS_IMAGE_EXTENSION.xz"
OS_IMAGE_QEMU_EXTENSION=".qcow2"
OS_SHA256=972f33fb741943c33833d9aeb3d71dbf57a3bd1144be503856a152373f69244a

# Set up handlers.

section() {
    echo
}

evoke() {
    WORKING_PATH=$(pwd | sed "s|$HOME|~|")
    echo ":$WORKING_PATH> $*" >> $DETAILED_LOGFILE
    "$@" >> $DETAILED_LOGFILE
}

print_evoke() {
    WORKING_PATH=$(pwd | sed "s|$HOME|~|")
    echo ":$WORKING_PATH> $*" >> $DETAILED_LOGFILE
    "$@" | tee -a $DETAILED_LOGFILE
}

export_evoke() {
    OUTPUT_FILE="$1"
    WORKING_PATH=$(pwd | sed "s|$HOME|~|")
    shift
    echo ":$WORKING_PATH> $* > $OUTPUT_FILE" >> $DETAILED_LOGFILE
    "$@" >> $OUTPUT_FILE
}

describe() {
    section
    echo "** $@ **"
}

start() {
    echo -n "$@ . . ."
}

finish() {
    echo " done!"
}

# Install all dependencies.

start "Installing dependencies"
evoke sudo zypper install -y qemu-extra guestfs-tools
finish

# Make a emulator directory.

evoke cd
evoke mkdir emulation
evoke cd emulation

# Download OpenSUSE image for RISC-V.

start "Downloading OpenSUSE image"
evoke wget "$OS_IMAGE_LOCATION$OS_IMAGE_NAME$OS_IMAGE_ARCHIVE_EXTENSION"
finish

start "Verifying $OS_IMAGE_NAME$OS_IMAGE_ARCHIVE_EXTENSION"
echo "$OS_SHA256 *$OS_IMAGE_NAME$OS_IMAGE_ARCHIVE_EXTENSION" | shasum -c
finish

start "Extracting $OS_IMAGE_NAME$OS_IMAGE_ARCHIVE_EXTENSION"
evoke xz -d openSUSE-Tumbleweed-RISC-V-JeOS-efi.riscv64-2024.09.02-Build1.35.raw.xz
finish

start "Converting $OS_IMAGE_NAME$OS_IMAGE_EXTENSION to qcow"
evoke qemu-img convert -f raw -O qcow2 -c $OS_IMAGE_NAME{$OS_IMAGE_EXTENSION,$OS_IMAGE_QEMU_EXTENSION}
finish

start "Extract /boot from $OS_IMAGE_NAME$OS_IMAGE_QEMU_EXTENSION"
evoke virt-copy-out -a $OS_IMAGE_NAME$OS_IMAGE_QEMU_EXTENSION /boot .
finish

echo "Reached target emulator launch"
print_evoke qemu-system-riscv64 -nographic -machine virt -m 4G -device virtio-blk-device,drive=hd0 -drive file=$OS_IMAGE_NAME$OS_IMAGE_QEMU_EXTENSION,format=qcow2,id=hd0,if=none -device virtio-net-device,netdev=usernet -netdev user,id=usernet,hostfwd=tcp::22222-:22 -kernel boot/u-boot.bin
