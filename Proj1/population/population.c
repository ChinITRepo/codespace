#include <cs50.h>
#include <stdio.h>

//function starts
long get_start_size(void);
long get_end_size(void);
void print_years(int y);

//main function
int main(void)
{
    // TODO: Prompt for start size
    n1 = get_start_size();

    // TODO: Prompt for end size
    n1 = get_end_size();

    // TODO: Calculate number of years until we reach threshold

    // TODO: Print number of years
    print_years(y)
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

int get_end_size(void)
{
    int n;
    do
    {
        n = get_long("END size: ");
    }
    while (n =< 0);
    return n;
}

