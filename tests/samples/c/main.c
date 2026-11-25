#include <stdio.h>

static int square(int x) { return x * x; }

int main(void) {
    int total = 0;
    for (int i = 0; i < 4; i++) {
        total += square(i);
    }
    printf("%d\n", total);
    return 0;
}
