#include <cs50.h>
#include <stdio.h>
#include <string.h>

int count_letters(string text);
int count_words(string text);
int count_sentences(string text);
int coleman_Liau_index(int l, int w, int s);

int main(void)
{
    string text = get_string("Text: ");
    int letters = count_letters(text);
    int words = count_words(text);
    int sentences = count_sentences(text);
    int grade = coleman_Liau_index(letters, words, sentences);
    printf("grade: %i\n", grade);

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
    else
    {
        return 1;
    }


    return 0;
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
    printf("Letters:%i\nWords:%i\nSentences:%i\n", letters,words,sentences);
    int average_letters = (words * 100) / letters;
    printf("average Let: %i\n", average_letters);
    int average_sentences = (words * 100) / sentences;
    printf("average Sen: %i\n", average_sentences);
    int index = 0.0588 * average_letters - 0.296 * average_sentences - 15.8;
    printf("index: %i\n", index);
    return index;
}
