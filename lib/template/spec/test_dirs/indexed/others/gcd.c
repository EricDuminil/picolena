/*
 * File: gcd.c
 * -----------
 * This program computes a greatest common divisor using
 * a brute-force algorithm.
 */

#include <stdio.h>
#include "genlib.h"
#include "simpio.h"

/* Function prototypes */

int GCD(int x, int y);

/* Main program */

main()
{
    int x, y;

    printf("This program calculates greatest common divisors.\n");
    printf("Enter two integers, x and y.\n");
    printf("x = ? ");
    x = GetInteger();
    printf("y = ? ");
    y = GetInteger();
    printf("The gcd of %d and %d is %d.\n", x, y, GCD(x, y));
}

/*
 * Function: GCD
 * Usage: gcd = GCD(x, y);
 * -----------------------
 * Returns the greatest common divisor of x and y,
 * calculated by the brute-force method of testing
 * every possibility.
 */

int GCD(int x, int y)
{
    int g;

    g = x;
    while (x % g != 0 || y % g != 0) {
        g--;
    }
    return (g);
}

