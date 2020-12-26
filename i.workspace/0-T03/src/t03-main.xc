/*
 * t03-main.xc
 *
 *  Created on: 11.04.2012
 *      Автор: Милен Луканчевски
 *      Exapmle: MTX 4
 *      Opeartor: select
 */

#include <xs1.h>

#define PARALLEL

typedef enum {FALSE=0, TRUE} BOOL;

#define STOP return;

const int LIMIT = 3;

const int MSG_PERIOD = 100000000;	// 1 sec

out port outportLeds = XS1_PORT_4F;

void taskP(chanend chanOut, int intDelay);	// P&Q
void taskC(chanend chanLeft, chanend chanRight);

void main(void)
{
	chan chanPC, chanQC;

	par
	{
		taskP(chanPC, MSG_PERIOD);	// P
		taskP(chanQC, MSG_PERIOD/4);	// Q
		taskC(chanPC, chanQC);	// C
	}

	outportLeds <: 0x0F;
	while(TRUE);
}

void taskP(chanend chanOut, int intDelay)
{
	int intMsg;
	timer timerT;
	int intT;

	timerT :> intT;
	intT += intDelay;

	intMsg = 0;

	while(TRUE)
	{
		intMsg++;
		if(intMsg > LIMIT)
			intMsg = 0;

		chanOut <: intMsg;

		timerT when timerafter(intT) :> void;
		intT += intDelay;
	}
}

void taskC(chanend chanLeft, chanend chanRight)
{
	int intVar, intLeds;

	intLeds = 0;
	outportLeds <: intLeds;

	while(TRUE)
	{
#if defined(PARALLEL)
		int intVar1, intVar2;

		par
		{
		  chanLeft :> intVar1;
		  chanRight :> intVar2;
		}

		intLeds = (intVar1 << 2) + intVar2;
#else
		select
		{
			case chanLeft :> intVar:
			{
				intLeds &= 0x03;
				intLeds += intVar << 2;
				break;
			}
			case chanRight :> intVar:
			{
				intLeds &= 0x0C;
				intLeds += intVar;
				break;
			}
		}
#endif
		outportLeds <: intLeds;
	}
}

