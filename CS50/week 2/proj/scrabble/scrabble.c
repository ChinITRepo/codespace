#include <cs50.h>
#include <stdio.h>
#include <string.h>

typedef struct
{
    int player_number;
    string word;
    int score;
}
player;

int calc_score(string word);
string word(void);

int main(void)
{


    if (playerarray[0].score > playerarray[1].score)
    {
        printf("player 1 wins!\n");
    }
    else if (playerarray[1].score > playerarray[0].score)
    {
        printf("Player 2 wins!\n");
    }
    else
    {
        printf("Tie!\n");
    }
}

string get_words(void)
{
    int players = 2;
    player playerarray[players];

    for (int i = 0; i < players; i++)
    {
        playerarray[i].player_number = i + 1;
        playerarray[i].score = 0;
        playerarray[i].word = get_string("player %i: ", playerarray[i].player_number);
        playerarray[i].score = calc_score(playerarray[i].word);
    }
    return playerarray[2];
}

int calc_score(string word)
{
    int score = 0;

    for (int i = 0; i < (int) strlen(word); i++)
    {
        switch(word[i])
        {
            case 'a'  :
            case 'A'  :
            case 'e'  :
            case 'E'  :
            case 'i'  :
            case 'I'  :
            case 'l'  :
            case 'L'  :
            case 'n'  :
            case 'N'  :
            case 'o'  :
            case 'O'  :
            case 'r'  :
            case 'R'  :
            case 's'  :
            case 'S'  :
            case 't'  :
            case 'T'  :
            case 'u'  :
            case 'U'  :
                score++;
                break;

            case 'd'   :
            case 'D'   :
            case 'g'   :
            case 'G'   :
                score += 2;
                break;

            case 'b'   :
            case 'B'   :
            case 'c'   :
            case 'C'   :
            case 'm'   :
            case 'M'   :
            case 'p'   :
            case 'P'   :
                score += 3;
                break;

            case 'h'   :
            case 'H'   :
            case 'v'   :
            case 'V'   :
            case 'y'   :
            case 'Y'   :
            case 'w'   :
            case 'W'   :
                score +=4 ;
                break;

            case 'k'   :
            case 'K'   :
                score += 5;
                break;

            case 'j' :
            case 'J' :
            case 'x' :
            case 'X' :
                score += 8;
                break;

            case 'q' :
            case 'Q' :
            case 'z' :
            case 'Z' :
                score += 10;
                break;

            default:
                score += 0;
                break;
        }
    }
    return score;
}
