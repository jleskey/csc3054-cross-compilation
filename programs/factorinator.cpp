#include <stdio.h>
#include <stdlib.h>

// Accidentially wrote this in C, but as we all know, C++ is a superset of C,
// so it's definitely a C++ program.

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
