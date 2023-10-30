#include <cs50.h>
#include <stdio.h>
#include <string.h>

int main(void)
{
    int players = 2;
    string words[players];

    for (int i = 0; i < players; i++)
    {
        printf("player %i: ", i + 1);
        words[i] = get_string("");
    }

    //switch(p1)
    //{
     //   case (p1 > p2):
     //       printf("Player 1 wins!");
       //     break;
       // case (p1 < p2):
       //     printf("Player 2 wins!");
       //     break;
       // default:
       //     printf("Tie!");
       //     break;
//}
}

int score(string word)
{
    int score = 0;
    for (int i = 0; i < strlen(word); i++)
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
                score += 1;
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
        }
    return score;
    }
}


//1	3	3	2	1	4	2	4	1	8	5	1	3	1	1	3	10	1	1	1	1	4	4	8	4	10
//For example, if we wanted to score the word “CODE”, we would note that the ‘C’ is worth 3 points, the ‘O’ is worth 1 point, the ‘D’ is worth 2 points, and the ‘E’ is worth 1 point. Summing these, we get that “CODE” is worth 7 points.

//implement a program in C that determines the winner of a short Scrabble-like game. Your program should prompt for input twice: once for “Player 1” to input their word and once for “Player 2” to input their word. Then, depending on which player scores the most points, your program should either print “Player 1 wins!”, “Player 2 wins!”, or “Tie!” (in the event the two players score equal points).


