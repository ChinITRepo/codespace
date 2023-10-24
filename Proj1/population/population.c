#include <cs50.h>
#include <stdio.h>

// Function prototypes
long get_start_size(void);
long get_end_size(void);
long calculate_years(long start, long end);
void print_results(long start, long end, long years);

// Main function
int main(void)
{
    // Prompt for start size
    long n1 = get_start_size();

    // Prompt for end size
    long n2 = get_end_size();

    // Calculate number of years until we reach threshold
    long n3 = calculate_years(n1, n2);

    // Print number of years
    print_results(n1, n2, n3);
}

long get_start_size(void)
{
    long n;
    do
    {
        n = get_long("Start size: ");
    }
    while (n < 9);
    return n;
}

long get_end_size(void)
{
    long n;
    do
    {
        n = get_long("End size: ");
    }
    while (n <= 0);
    return n;
}

long calculate_years(long start, long end)
{
    long i;
    for (i = 0; start < end; i++)
    {
        long gain = start / 3;
        long loss = start / 4;
        start = start + (gain - loss);
    }
    return i;
}

void print_results(long start, long end, long years)
{
    printf("Start size: %li\nEnd size: %li\nYears: %li\n", start, end, years);
}
