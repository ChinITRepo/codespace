#include <stdio.h>
#include <cs50.h>

int scores();

int main(void)
{
    scores(3);
    printf("Average: %f\n", ((float) scores[0] + (float) scores[1] + (float) scores[2]) / 3);
}

int scores(n)
{
    int scores[n]
    for (int i = 0; 1 < n; i++)
    {
        do
        scores[i] = get_int("Score: ");
        while (scores[i] > 1);
    }
}