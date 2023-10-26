#include <stdio.h>
#include <stdlib.h>
#include <cs50.h>

int scores();
float average();

int main(void)
{
    j = get_int("How many scoresn would you like to average?")
    scores(j);
    printf("Average: %f\n", average);
}



int scores(int n)
{
    int scores[n];
    for (int i = 0; 1 < n; i++)
    {
        do
        scores[i] = get_int("Score: ");
        while (scores[i] > 1);
    }
}

float average(int n, array scores)
{

}