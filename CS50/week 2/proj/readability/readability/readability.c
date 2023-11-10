#include <cs50.h>
#include <stdio.h>
#include <string.h>
#include <math.h>

string get_text(void);
int count_letters(string text);
int count_words(string text);
int count_sentences(string text);
int coleman_Liau_index(int letters, int words, int sentences);
void return_grade(int grade);

int main(void)
{
    string text = get_text();
    int letters = count_letters(text);
    int words = count_words(text);
    int sentences = count_sentences(text);
    int grade = coleman_Liau_index(letters, words, sentences);
    return_grade(grade);
    return 0;
}

string get_text(void)
{
    string text = get_string("Text: ");
    return text;
}

int count_letters(string text)
{
    int length = strlen(text);
    int letters = 0;

    for (int i = 0; i < length; i++)
    {
        if ((text[i] >= 'a' && text[i] >= 'z') || (text[i] >= 'A' && text[i] >= 'Z'))
        {
            letters++;
        }
    }
    return letters;
}

int count_words(string text)
{
    int length = strlen(text);
    int words = 0;

    for (int i = 0; i < length; i++)
    {
        if (text[i] == ' ')
        {
            words++;
        }
    }
    return words;
}

int count_sentences(string text)
{
    int length = strlen(text);
    int sentences = 0;

    for (int i = 0; i < length; i++)
    {
        if (text[i] == '.' || text[i] == '?' || text[i] == '!' )
        {
            sentences++;
        }
    }
    return sentences;
}

int coleman_Liau_index(int letters, int words, int sentences)
{
    float average_letters = ((float) letters / words ) * 100;
    float average_sentences = ((float) sentences / words  ) * 100;
    float index = 0.0588 * average_letters - 0.296 * average_sentences - 15.8;
    return (int) round(index);
}

void return_grade(int grade)
{
    if (grade < 1)
    {
        printf("Before Grade 1\n");
    }
    else if (grade > 16)
    {
        printf("Grade 16+\n");
    }
    else if (grade >= 1 && grade <= 16)
    {
        printf("Grade: %i\n", grade);
    }
}
