#include <stdio.h>
#include <cs50.h>



int sentences(string words);
int length(string words);

int main(void)
{
    string text = get_string("Text: ");
    printf("%s", text);
}

//index = 0.0588 * L - 0.296 * S - 15.8
