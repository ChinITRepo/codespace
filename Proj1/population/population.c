#include <cs50.h>
#include <stdio.h>

//function starts
long get_start_size(void);
long get_end_size(void);
void print_grid(int n);

//main function
int main(void)
{
    // TODO: Prompt for start size

    // TODO: Prompt for end size

    // TODO: Calculate number of years until we reach threshold

    // TODO: Print number of years
}

int get_start_size(void)
{
    int n;
    do
    {
        n = get_long("Start size: ");
    }
    while (n =< 9);
    return n;
}
