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
    // Loop through each level of the pyramid
    for (int i = 1; i <= size; i++)
    {
        // Print spaces before #
        for (int j = 0; j < size - i; j++)
        {
            printf(" ");
        }

        // Print # for the left pyramid
        for (int j = 0; j < i; j++)
        {
            printf("#");
        }

        // Print two spaces in the middle
        printf("  ");

        // Print # for the right pyramid
        for (int j = 0; j < i; j++)
        {
            printf("#");
        }

        // Move to the next line
        printf("\n");
    }
}
