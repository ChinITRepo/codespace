#include <cs50.h>
#include <stdio.h>

//function starts
long get_start_size(void);
long get_end_size(void);
long calculate_years(long start, long end);
void print_results(long start, long end, long years);

//main function
int main(void)
{
    // TODO: Prompt for start size
    long n1 = get_start_size();

    // TODO: Prompt for end size
    long n2 = get_end_size();

    // TODO: Calculate number of years until we reach threshold
    long n3 = calculate_years(n1, n2);

    // TODO: Prlongnumber of years
    print_results(n1, n2, n3);
}

long get_start_size(void)
{
    long n;
    do
    {
        n = get_long("Start size: ");
    }
    while (n >= 9);
    return n;
}

long get_end_size(void)
{
    long n;
    do
    {
        n = get_long("END size: ");
    }
    while (n <= 0);
    return n;
}

long calculate_years(long start, long end)
{
    for (long i = start; i <= end; i++)
    {
        long gain = start / 3;
        long loss = start / 4;
        long start = start + (gain - loss)
    }
    return 
}

void print_results(long start, long end, long years)
{
    printf("Start size: %li\nEnd size: %li\nYears: %li\n")
}