/*
 * t01-main.xc
 *
 *  Created on: 03.04.2012
 *      �����: ����� �����������
 *      MTX:2.1
 *      Oparators: par, !, ?
 *      Type: chan, timer, port
 */

#include <xs1.h>

typedef enum {FALSE=0, TRUE} BOOL;

#define STOP return;

const int LIMIT_P = 10;
const int LIMIT_Q = 10;

const int MSG_PERIOD = 100000000;	// 1 sec

out port outportLeds = XS1_PORT_4F;

void taskP(chanend chanOut);
void taskQ(chanend chanIn);

void main(void)
{
	chan chanPQ;

	par
	{
		taskP(chanPQ);
		taskQ(chanPQ);
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

		if(intMsg <= LIMIT_P)
		{
			chanOut <: intMsg;

			timerT when timerafter(intT) :> void;
			intT += MSG_PERIOD;
		}
		else
			STOP;
	}
}

void taskQ(chanend chanIn)
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

		if(intVar >= LIMIT_Q)
			STOP;
	}
}

