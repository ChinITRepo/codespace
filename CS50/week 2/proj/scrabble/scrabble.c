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

int main(void)
{
    int players = 2;
    player playerarray[players];

    for (int i = 0; i < players; i++)
    {
        playerarray[i].player_number = i + 1;
        playerarray[i].score = 0;
        do
        {
            playerarray[i].word = get_string("player %i: ", playerarray[i].player_number);
        }
        while (playerarray[i].word == NULL);
        playerarray[i].score = calc_score(playerarray[i].word);
        printf("Player: %i\nWord: %s\nScore: %i\n",playerarray[i].player_number, playerarray[i].word, playerarray[i].score);
    }

    if (playerarray[0].score > playerarray[1].score)
    {
        printf("player 1 wins!\n");
    }
    else if (playerarray[0].score > playerarray[1].score)
    {
        printf("Player 2 wins!\n");
    }
    else
    {
        printf("Tie!\n");
    }
}

int calc_score(string word)
{
    int score = 0;

    for (int i = 0; i < (int) strlen(word); i++)
    {
        switch(word[i])
        {
            case 'a'  :
            case 'e'  :
            case 'i'  :
            case 'l'  :
            case 'n'  :
            case 'o'  :
            case 'r'  :
            case 's'  :
            case 't'  :
            case 'u'  :
                score++;
                break;

            case 'd'   :
            case 'g'   :
                score += 2;
                break;

            case 'b'   :
            case 'c'   :
            case 'm'   :
            case 'p'   :
                score += 3;
                break;

            case 'h'   :
            case 'v'   :
            case 'w'   :
            case 'y'   :
                score +=4 ;
                break;

            case 'k'   :
                score += 5;
                break;

            case 'j' :
            case 'x' :
                score += 8;
                break;

            case 'q' :
            case 'z' :
                score += 10;
                break;

            default:
                score += 0;
                break;
        }
    }
    return score;
}
