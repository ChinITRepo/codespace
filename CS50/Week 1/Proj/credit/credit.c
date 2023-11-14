#include <stdio.h>
#include <cs50.h>

struct 
{

}
int check_length(long);
void check_brand(long);


int main(void)
{
    long card_number = get_long("Number: ");
    int length = check_length(card_number);
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
        printf("INVLAID\n");
    }
    return length;
}

void check_brand(long)
{

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
