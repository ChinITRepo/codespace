#include <stdio.h>
#include <cs50.h>

int get_scores(int length, int scores[]);
float average(int length, int scores[]);

int n = 3;

int main(void)
{
    int scores[n];

    for (int i = 0; i < length; i++)
    {
        do
        {
            scores[i] = get_int("Score for Test %i: ", i);
        }
        while (scores[i] <= 0);
    }
    float avg = average(n, scores);
    printf("Average: %f\n", avg);
}

int get_scores(int length, int scores[])
{
    for (int i = 0; i < length; i++)
    {
        do
        {
            scores[i] = get_int("Score for Test %i: ", i);
        }
        while (scores[i] <= 0);
    }

    return scores;
}

float average(int length, int scores[])
{
    int sum = 0;
    for (int i = 0; i < length; i++)
    {
        sum += scores[i];
    }
    return float average = sum / (float) length;
}