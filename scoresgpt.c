#include <stdio.h>

#include <cs50.h>

// Function prototypes
int* scores(int n);
float average(int n, int scores[]);

int main(void)
{
    int j = get_int("How many scores would you like to average? ");
    int *scoreArray = scores(j);
    printf("Average: %f\n", average(j, scoreArray));
}

// Function to get scores
int* scores(int length)
{
    // Dynamically allocate memory for scores
    int *scores = malloc(n * sizeof(int));
    for (int i = 0; i < n; i++)
    {
        do
        {
            scores[i] = get_int("Score: ");
        } while (scores[i] < 1); // Assuming you only want scores greater than or equal to 1
    }
    return scores;
}

// Function to calculate average
float average(int length, int scores[])
{
    float sum = 0;
    for (int i = 0; i < n; i++)
    {
        sum += scores[i];
    }
    return sum / n;
}
