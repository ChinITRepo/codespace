#include <stdio.h>
#include <cs50.h>

int get_scores(int tests, int scores[]);
float average(int tests, int scores[]);

int main(void)
{
    int tests = 3;
    get_scores(tests, scores[]);
    average(tests, scores[]);
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
       for (int i = 0; 1 < tests; i++)
       {
            scores[i] = get_int("Score for Test %s: ", i);
       }
    }
    while (!scores[] || scores <= 0);
    return tests;
    return scores[];
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