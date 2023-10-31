#include <cs50.h>
#include <stdio.h>

// Function prototypes
int userinput(void);
void pyramid_create(int size);

int main(void)
{
    //TODO: Get user input, int 1-8
    int n = userinput();

    //TODO: Define pyramid
    pyramid_create(n);
}

int userinput(void)
{
    int n;
    do
    {
        n = get_int("Pyramid size (1-8): ");
    }
    while (n <= 0 || n > 8);  // Corrected condition
    return n;
}

void pyramid_create(int size)
{
    for (int i = 0; i < size; i++)
    {

    }
}
