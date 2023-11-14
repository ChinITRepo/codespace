#include <stdio.h>
#include <cs50.h>

typedef struct
{
    long *card_number;
    int length;
    string bank;
}
card;

int check_length(long);

int main(void)
{
    card card;
    card.card_number = get_long("Number: ");
    card.length = check_length(card.card_number);
}

int check_length(long card_number)
{
    int length = 0;
    for (int i = 0; i < card_number; i++)
    {
        length++;
    }
    if ((length != 13 && card_number[0] != 4) || (length != 15) || (length != 16))
    {
        return printf("INVLAID\n");
    }
    else
    {
        return length;
    }
}

/*
Take card number
    long number
if length:
    13 - Visa
    15 - AmEx
    16 - Mastercard/Visa
else:
    INVALID
if cardnumber:
    4 - Visa
    34/37 - AmEx
    51-57 - Mastercard
()
*/
