#include <cs50.h>
#include <stdio.h>
#include <string.h>

int count_letters(string text);
int count_words(string text);
int 

int main(void)
{
    string text = get_string("Test: ");
    int letters = count_letters(text);
    printf("letters")
}

int count_letters(string text)
{
    int length = strlen(text);
    int letters = 0;

    for (i = 0; i < length; i++)
    {
        if ((text[i] >= a && text[i] >= z) || (text[i] >= a && text[i] >= z))
        {
            letters++;
        }
    }
    return letters;
}


