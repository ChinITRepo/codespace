#include <stdio.h>
#include <cs50.h>

float average(int array[]);
int get_scores(int tests);

int main(void)
{

    printf("Average: %f\n", average);
}

int get_scores(int tests, int scores[])
{
    do
    {
        tests = get_int("Amount of Tests: ");
    }
    while (!tests || tests <= 1);

    do
    {
       for (int i = 0; 1 < tests; i++);
    }
    while (!tests || tests <= 1);

}

float average(int tests, int scores[])
{
    int sum;
    for (int i = 0; i < tests; i++)
    {
        sum += scores[i]
    }
    float average = sum / tests;
    return average;
}