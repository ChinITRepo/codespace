#include <cs50.h>
#include <stdio.h>
#include <string.h>

int count_letters(string text);
int count_words(string text);
int count_sentences(string text);

int main(void)
{
    string text = get_string("Test: ");
    int letters = count_letters(text);
    int words = count_words(text);
    int sentences = count_sentences(text);
    printf("letters:%i\nWords:%i\nSentences:%i", letters, words, sentences);
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

