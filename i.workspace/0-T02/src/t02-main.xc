/*
 * t02-main.xc
 *
 *  Created on: 11.04.2012
 *      Автор: Милен Луканчевски
 *      Example: MTX 2.2
 */

#include <xs1.h>

typedef enum {FALSE=0, TRUE} BOOL;

#define STOP return;

const int LIMIT = 10;

const int MSG_PERIOD = 100000000;	// 1 sec

out port outportLeds = XS1_PORT_4F;

void taskP(chanend chanOut);
void taskQ(chanend chanIn, chanend chanOut);
void taskC(chanend chanIn);

void main(void)
{
	chan chanPQ, chanQC;

	par
	{
		taskP(chanPQ);
		taskQ(chanPQ, chanQC);
		taskC(chanQC);
	}

	outportLeds <: 0x0F;
	while(TRUE);
}

void taskP(chanend chanOut)
{
	int intMsg;
	timer timerT;
	int intT;

	timerT :> intT;
	intT += MSG_PERIOD;

	intMsg = 0;

	while(TRUE)
	{
		intMsg++;

		if(intMsg <= LIMIT)
		{
			chanOut <: intMsg;

			timerT when timerafter(intT) :> void;
			intT += MSG_PERIOD;
		}
		else
			STOP;
	}
}

void taskQ(chanend chanIn, chanend chanOut)
{
	int intVar;

	while(TRUE)
	{
		select
		{
			case chanIn :> intVar:
			{
				chanOut <: intVar;
				break;
			}
		}

		if(intVar >= LIMIT)
			STOP;
	}
}

void taskC(chanend chanIn)
{
	int intVar;

	while(TRUE)
	{
		select
		{
			case chanIn :> intVar:
			{
				outportLeds <: intVar;
				break;
			}
		}

		if(intVar >= LIMIT)
			STOP;
	}
}

