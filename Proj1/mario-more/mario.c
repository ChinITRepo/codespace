#include <cs50.h>
#include <stdio.h>

int main(void)
{
    //TODO: Get user input, int 1-8
    int n = userinput();
    //TODO: Define pyramid
    pyramid_create(n);

    //TODO: Print pyramid
}

int userinput(void)
{
    int n;
    do
    {
        n = get_int("Pyramid size (1-8): ");
    }
    while (n > 0 || n < 9);
    return n;
}

void pyramid_create(int size)
{
    for (int i = 0; i < size; i++)
    {
        if
        printf("#");

    }
}