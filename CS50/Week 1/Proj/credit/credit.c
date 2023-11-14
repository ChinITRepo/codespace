#include <stdio.h>
#include <cs50.h>
#include <math.h>

int check_length(long);


int main(void)
{
    long card_number = get_long("Number: ");
    check_length(card_number);
}

int check_length(long)
{
    int length = 0;
    for (int i = 0; i < card_number; i++)
    {
        length++;
    }
    if (length != 13 || 15 || 16)
    {
        printf("INVLAID\n");
    }
    return length;
}

/*
Take card number
    long number
if length:
    15 - amex
    16
*/
