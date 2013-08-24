#include <stdio.h>
#include <stdlib.h>

int main(int argc, const char* argv[]) {
    int i;
    for (i = 0; i < argc; i++) {
        printf("argv[%d] = %s\n", i, argv[i]);
    }

    // can catch failures like so:
    //exit(EXIT_FAILURE);

    return 0;
}
