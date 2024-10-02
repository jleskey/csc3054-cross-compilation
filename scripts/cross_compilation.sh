# Ensure the script fails if an error occurs.

set -e

# Set constants.

DETAILED_LOGFILE=joseph_leskey_lab0_log.txt
ARCH=$(uname -m)

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
# gcc and gcc-c++ compile native binaries.
# gcc-c++ provides pthreads support.
# cross-riscv64-gcc14 and cross-riscv64-elf-gcc14 compile riscv64 binaries.
# dtc, libboost_regex-devel, libboost_system-devel are Spike dependencies.
# make runs the build processes.
# git-core provides Git access.

start "Installing dependencies"
evoke sudo zypper install -y gcc gcc-c++ cross-riscv64-gcc14 cross-riscv64-elf-gcc14 dtc libboost_regex-devel libboost_system-devel make git-core
finish

# Make some useful directories.

cd
evoke mkdir sources programs

# Enter the sources directory and clone relevant repositories.

start "Cloning proxy kernel and Spike emulator for RISC-V"
evoke cd sources
evoke git clone https://github.com/riscv-software-src/riscv-pk.git
evoke git clone https://github.com/riscv-software-src/riscv-isa-sim.git
finish

# Build the RISC-V Proxy Kernel.
# This build process should target the chosen RISC-V architecture.
# Choose the host prefix that matches the chosen cross-compiler.
# Use --prefix=<some path> to choose a non-default install path.
# The proxy kernel provides kernel-like functionality necessary for I/O
# operations and such.

start "Building the proxy kernel"
evoke cd riscv-pk
# Avoid broken code.
evoke git checkout -b safe-branch 1a52fa44
evoke mkdir build
evoke cd build
evoke ../configure --host=riscv64-elf
evoke make
finish

start "Installing the proxy kernel"
evoke sudo make install
finish

# Build the Spike emulator.
# This build process should target the native architecture. It will run
# directly on the host system.
# Use --prefix=<some path> to choose a non-default install path.

start "Building the Spike emulator"
evoke cd ../../riscv-isa-sim
evoke mkdir build
evoke cd build
evoke ../configure
evoke make
finish

start "Installing the Spike emulator"
evoke sudo make install
finish

# Write the test programs.

evoke cd ~/programs

start "Writing the hello world program"
cat << EOF > ~/programs/hello.c
#include <stdio.h>

int main() {
    printf("Hello world!\n");
}
EOF
finish

start "Writing the factorinator program"
cat << EOF > ~/programs/factorinator.cpp
#include <stdio.h>
#include <stdlib.h>

// Accidentially wrote this in C, but as we all know, C++ is a superset of C,
// so it's definitely a C++ program as well.

int main(int argc, char const *argv[])
{
    if (argc > 1) {
        int number = atoi(argv[1]);
        printf("Factors of %d:", number);
        for (int i = 1; i <= number; i++) {
            if (number % i == 0) {
                printf(" %d", i);
            }
        }
        printf("\n");
    } else {
        printf("Mate. I need a number.\n");
    }
}
EOF
finish

# Compile hello world program for native and riscv64 architectures.

start "Compiling native hello world program ($ARCH target)"
evoke gcc -o hello-$ARCH hello.c
finish

start "Cross-compiling hello world program (riscv64 target)"
evoke riscv64-elf-gcc -o hello-riscv64 hello.c
finish

# Describe and run the two resulting binaries.

describe "file hello-$ARCH"
print_evoke file hello-$ARCH

describe "file hello-riscv64"
print_evoke file hello-$ARCH

describe "run hello-$ARCH"
print_evoke ./hello-$ARCH

describe "run hello-riscv64"
print_evoke spike /usr/local/riscv64-elf/bin/pk hello-riscv64

section

# Compile factorinator program for native and riscv64 architectures.

start "Compiling native factorinator program ($ARCH target)"
evoke g++ -o factorinator-$ARCH factorinator.cpp
finish

start "Cross-compiling factorinator program (riscv64 target)"
evoke riscv64-elf-g++ -o factorinator-riscv64 factorinator.cpp
finish

# Describe, run, and time the two resulting binaries.

describe "time native factorinator-$ARCH"
print_evoke time ./factorinator-$ARCH

describe "time emulated factorinator-riscv64"
print_evoke time spike /usr/local/riscv64-elf/bin/pk factorinator-riscv64

describe "time native factorinator-$ARCH, \$1 = $((2**28))"
print_evoke time ./factorinator-$ARCH $((2**28))

describe "time emulated factorinator-riscv64, \$1 = $((2**28))"
print_evoke time spike /usr/local/riscv64-elf/bin/pk factorinator-riscv64 $((2**28))

section

# Save description of hello world program binary instructions.

start "Disassembling hello-$ARCH to hello-$ARCH.dumped.txt"
export_evoke hello-$ARCH.dumped.txt objdump --disassemble-all hello-$ARCH

start "Disassembling hello-riscv64 to hello-riscv64.dumped.txt"
export_evoke hello-riscv64.dumped.txt riscv64-elf-objdump --disassemble-all hello-riscv64

# Find entry point of hello world binary.

describe "header hello-$ARCH (including entry point address)"
print_evoke objdump -f hello-$ARCH

section

# Generate hex file representation of hello world binary.
# elf2hex only works for RISC-V.

describe "hex repr hello-riscv64"
export_evoke hello-riscv64.hex.txt elf2hex 16 32768 hello-riscv64

# Display hex representation.

describe "hex dump hello-riscv64.hex.txt"
evoke hexdump -C hello-riscv64.hex.txt

# Display binary sizes

describe "size hello-$ARCH"
evoke size hello-$ARCH

describe "size hello-riscv64"
evoke riscv64-elf-size hello-riscv64

describe "nm hello-$ARCH"
evoke nm --print-size hello-$ARCH

describe "nm hello-riscv64"
evoke riscv64-elf-nm --print-size hello-riscv64
