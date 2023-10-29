#include <stdio.h>
#include <cs50.h>

void get_length(string input);

int main(void)
{
    string input = get_string("Whats your name?");
    get_length(input);

}

void get_length(string input)
{
    int length = 0;
    for (int i = 0; i < input[]; i++)
    {
        length++;
    }
    return printf("%s is %i characters!", input, length);
}