#include <stdio.h>
#include <cs50.h>

int main(void)
{
    string name = get_string("Whats your name? ");
    printf("hello, %s\n", name);
}
