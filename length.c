#include <stdio.h>
#include <cs50.h>

void get_length(string input);

int main(void)
{
    string input = get_string("Whats your name? ");
    get_length(input);

}

void get_length(string input)
{
    int length = 0;
    do
    {
        length++;
    }
    while (input[length] != 0);
    printf("%s is %i characters!\n", input, length);
}