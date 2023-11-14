#include <stdio.h>
#include <cs50.h>
#include <math.h>

int main(void)
{
    card_number();
}

long check_number(void)
{
    long card_number = get_long("Number: ");
    int length = 0;
    for (int i = 0; i < card_number; i++)
    {
        length++
    }
    if (length != 13 || 15 || 16)
    {
        printf("INVLAID\n");
    }

}

/*
Take card number
    long number
if length:
    15 - amex
    16
*/
