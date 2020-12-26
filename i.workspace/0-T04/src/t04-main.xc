/*
 * t04-main.xc
 *
 *  Created on: 11.04.2012
 *      Автор: Милен Луканчевски
 *      Note: select; структурирано съобщение
 */

#include <xs1.h>
#include <string.h>
#include <stdio.h>

typedef enum {FALSE=0, TRUE} BOOL;

#define STOP return;

const int LIMIT = 3;

const int MSG_PERIOD = 100000000;	// 1 sec

#define CMD_LEN 128
typedef struct
{
	int x;
	char cmd[CMD_LEN + 1];
} MSG;
#define CMD_EMPTY "-"
#define CMD_STOP "STOP"

out port outportLeds = XS1_PORT_4F;
in port inportButton0 = XS1_PORT_1K;
in port inportButton1 = XS1_PORT_1L;

void taskP(chanend chanOut, in port inportB, int intDelay);	// P&Q
void taskC(chanend chanLeft, chanend chanRight);

void main(void)
{
	chan chanPC, chanQC;

	par
	{
		taskP(chanPC, inportButton0, MSG_PERIOD);	// P
		taskP(chanQC, inportButton1, MSG_PERIOD/4);	// Q
		taskC(chanPC, chanQC);	// C
	}

	outportLeds <: 0x0F;
	while(TRUE);
}

void taskP(chanend chanOut, in port inportB, int intDelay)
{
	MSG msgMsg;
	timer timerT;
	int intT;

	timerT :> intT;
	intT += intDelay;

	msgMsg.x = 0;
	sprintf(msgMsg.cmd, CMD_EMPTY);

	while(TRUE)
	{
		msgMsg.x++;
		if(msgMsg.x > LIMIT)
			msgMsg.x = 0;

		chanOut <: msgMsg;

		select
		{
			case timerT when timerafter(intT) :> void:
			{
				intT += intDelay;
				break;
			}
			case inportB when pinseq(0) :> void:
			{
				sprintf(msgMsg.cmd, CMD_STOP);
				chanOut <: msgMsg;
				STOP;
				break;
			}
		}
	}
}

void taskC(chanend chanLeft, chanend chanRight)
{
	MSG msgVar;
	int intLeds;
	BOOL boolStopP = FALSE, boolStopQ = FALSE;

	intLeds = 0;
	outportLeds <: intLeds;

	while(TRUE)
	{
		select
		{
			case chanLeft :> msgVar:
			{
				intLeds &= 0x03;
				intLeds += msgVar.x << 2;
				if(!strcmp(msgVar.cmd, CMD_STOP))
					boolStopP = TRUE;
				break;
			}
			case chanRight :> msgVar:
			{
				intLeds &= 0x0C;
				intLeds += msgVar.x;
				if(!strcmp(msgVar.cmd, CMD_STOP))
					boolStopQ = TRUE;
				break;
			}
		}

		outportLeds <: intLeds;

		if(boolStopP && boolStopQ)
			STOP;
	}
}

