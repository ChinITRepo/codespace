#include <stdio.h>
#include <cs50.h>

typedef struct
{
    long card_number;
    int length;
    string bank;
}
card;

int check_length(long);
void check_start(long);


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
    if (length != 13 || 15 || 16)
    {
        return printf("INVLAID\n");
    }
    else
    {
        return length;
    }
}

void check_start(long card_number)
{
    if (card_number[0] = 4)
    {
        return;
    }

    int numbers = 2;
    string bank;

    for (int i = 0; i < numbers; i++)
    {

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
