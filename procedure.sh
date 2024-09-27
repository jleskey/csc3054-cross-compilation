# Ensure the script fails if an error occurs.

set -e

# Set constants.

DETAILED_LOGFILE=detailed_log.txt

# Set up handlers.

evoke() {
    WORKING_PATH=pwd | sed "s|$HOME|~|"
    echo ":$WORKING_PATH> $*" >> $DETAILED_LOGFILE
    "$@" >> $DETAILED_LOGFILE
}

start() {
    echo -n "$@ . . ."
}

end() {
    echo " done!"
}

# Install all dependencies.
# gcc compiles native binaries.
# gcc-c++ provides pthreads support.
# cross-riscv64-gcc14 and cross-riscv64-elf-gcc14 compile riscv64 binaries.
# dtc, libboost_regex-devel, libboost_system-devel are Spike dependencies.
# make runs the build processes.
# git-core provides Git access.

start "Installing dependencies"
evoke sudo zypper install gcc gcc-c++ cross-riscv64-gcc14 cross-riscv64-elf-gcc14 dtc libboost_regex-devel libboost_system-devel make git-core
finish

# Make some useful directories.

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

# Build the test programs in the native architecture and RISC-V.

start "Determining architecture"
evoke export ARCH=$(uname -m)
finish

start "Compiling native hello world program ($ARCH target)"
evoke gcc -o hello-$ARCH hello.c
finish

start "Cross-compiling hello world program (riscv64 target)"
evoke riscv64-elf-gcc -o hello-riscv64 hello.c
finish
