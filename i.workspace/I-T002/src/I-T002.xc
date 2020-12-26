/*
 * I-T002.xc
 *
 *  �������� ��: 23.05.2012
 *        �����: ����� �����������
 *
 *   ����������:
 *   - LFSR ������������ �� ��������;
 *   - LFSR ������������ �� �����;
 *   - ���������-� (����);
 *   - ���������, ������� �� ������������ ������� crc32 �� �������������� �����.
 *
 *      �� ��������� �� ������������ ���������������� �� �������� �������:
 *      XD0[P1A0] >>> �������� ����������������
 *
 *      �� ���������� �� ������� taskL �� �������� �������:
 *      XD1[P1B0] >>> ����� ������ >>> XD13[P1F0]
 *
 *      ���������� �� ������������ ������� crc32:
 *      Random-numbers-on-the-XS1-L1(1.0).pdf - �.2
 *      XS1-Library(X6020B).pdf - �.10
 *      xs1_en.pdf - �.18, ���. 74
 *
 */

#include <xs1.h>
#include <stdlib.h>
//#include <string.h>
//#include <stdio.h>

#define RNG_TYPE	4
// 1 - LFSR ������������ �� ��������
// 2 - LFSR ������������ �� �����
// 3 - Algorithm-M
// 4 - ��������� � ���������� ������� crc32 �� ������������

#define LFSR_F_VER	2
// 1 - RNG_LFSR_F() ������ � �������� �������
// 2 - RNG_LFSR_F() ������ � �������, ������� ���� ���������

typedef enum {FALSE=0, TRUE} BOOL;
typedef unsigned int UINT;
typedef unsigned char BYTE;

in port iportButStart = XS1_PORT_1K;	// ����� ���������� �� �����������
in port iportButStop  = XS1_PORT_1L;	// ����� ������� ����������� ��
										// �������������� ����������������

out port oportRngBit = XS1_PORT_1A;	// ���� �� ��������� ��
									// ������������ ����������������
out port oportSync   = XS1_PORT_1B;	// ������� ��������� ������ ��
									// ���������� �� ������������������
in port  iportSync   = XS1_PORT_1F;	// ������ ��������� ������
									// �� ���������� �� ������������������

out port oportLed    = XS1_PORT_4F;	// ���� �� ������������� ���������
int intLed = 0;

#define NN		1024				// ���������� �� ������ � ���������
const int M = 32;					// ������� �� ���������
const int N = NN;					// ������ �� ��������� � words

#define NN_AM	8192				// ���������� �� ������ � ���������-�
UINT uintDelay[NN_AM]; 				// ������� ����� � ���������-�

const int LED_PERIOD = 12500000;	// ������ �� ���/���� �� ����������:
									// (10^8, 1/sec) * (0.125, sec)

UINT uintShiftReg = 1;				// LFSR  - �������� ��������� �� ����������
UINT uintCRC32Reg = 1;				// CRC32 - �������� ��������� �� ����������
UINT uintRandomArr[NN];				// ����� �� ���������� ����������������

void taskP(chanend chanRight);
void taskQ(chanend chanLeft);
void taskL(void);

int SetLed(int intL);

void Randomize(void);
UINT RNG_LFSR_F(UINT uintSeed, UINT uintPoly);
UINT RNG_LFSR_G(UINT uintSeed, UINT uintPoly);
UINT RNG_ALG_M(UINT uintSeed, UINT uintPoly);
UINT RNG_CRC32(UINT uintSeed, UINT uintPoly);

int main(void)
{
	chan chanPC;

	oportSync <: 0;

	intLed = 0;
	oportLed <: intLed;

	Randomize();

	par
	{
		taskP(chanPC);
		taskQ(chanPC);
		taskL();
	}

	oportLed <: 0;

	return 0;
}

void taskP(chanend chanRight)
{
	UINT uintMsg;
	int intButStop;

	// ��������� �� �����
	iportButStart when pinseq(0) :> void;

	// ���������� �� ������ ����������������
	for(int i = 0; i < N*M; i++)
	{
#if (RNG_TYPE == 1)
		uintMsg = RNG_LFSR_F(0, 0x80000057);

		chanRight <: uintMsg;
		oportSync <: 1;
#elif (RNG_TYPE == 2)
		uintMsg = RNG_LFSR_G(0, 0x80000057);

		chanRight <: uintMsg;
		oportSync <: 1;
#elif (RNG_TYPE == 3)
		uintMsg = RNG_ALG_M(0, 0x80000057);

		// �������������
		for(int i = 0; i < M; i++)
		{
		  chanRight <: (uintMsg & 0x1);
		  uintMsg >>= 1;

		  oportSync <: 1;
		}
#elif (RNG_TYPE == 4)
		uintMsg = RNG_CRC32(0, 0xEB31D82E);

		// �������������
		for(int i = 0; i < M; i++)
		{
		  chanRight <: (uintMsg & 0x1);
		  uintMsg >>= 1;

		  oportSync <: 1;
		}
#else
	#error INVALID RNG_TYPE
#endif
	}

	// ���������� �� ������������ ����������������
	while(TRUE)
	{
		iportButStop :> intButStop;
		if(intButStop == 0)
		{
			oportSync <: 0;

			// ��������� �� �������� �����
			iportButStart when pinseq(0) :> void;
		}

#if (RNG_TYPE == 1)
		uintMsg = RNG_LFSR_F(0, 0x80000057);
		chanRight <: uintMsg;
		oportSync <: 1;
#elif (RNG_TYPE == 2)
		uintMsg = RNG_LFSR_G(0, 0x80000057);
		chanRight <: uintMsg;
		oportSync <: 1;
#elif (RNG_TYPE == 3)
		uintMsg = RNG_ALG_M(0, 0x80000057);

		// �������������
		for(int i = 0; i < M; i++)
		{
		  chanRight <: (uintMsg & 0x1);
		  uintMsg >>= 1;

		  oportSync <: 1;
		}
#elif (RNG_TYPE == 4)
		uintMsg = RNG_CRC32(0, 0xEB31D82E);

		// �������������
		for(int i = 0; i < M; i++)
		{
		  chanRight <: (uintMsg & 0x1);
		  uintMsg >>= 1;

		  oportSync <: 1;
		}
#else
	#error INVALID RNG_TYPE
#endif
	}
}

void taskQ(chanend chanLeft)
{
	int i, j;
	UINT uintMsg;

	for (i = 0; i < N; i++)
	{
		// ����������
		for (j = 0; j < M; j++)
		{
			chanLeft :> uintMsg;
			oportRngBit <: uintMsg;

			uintMsg = uintMsg << 31;
			uintRandomArr[i] = uintMsg | (uintRandomArr[i] >> 1);
		}
	}

	while(TRUE)
	{
		chanLeft :> uintMsg;
		oportRngBit <: uintMsg;
	}
}

void taskL(void)
{
	timer timerT;
	int intT;

	timerT :> intT;
	intT += LED_PERIOD;

	while(TRUE)
	{
		// ��������� �� ��. �����
		iportSync when pinseq(1) :> void;

		intLed = (intLed & 0xC) | SetLed(intLed);
		oportLed <: intLed;

		timerT :> intT;
		intT += LED_PERIOD;
		timerT when timerafter(intT) :> void;
	}
}

int SetLed(int intL)
{
	switch(intL & 0x3)
	{
	case 0x0:
		return 0x1;
	case 0x1:
		return 0x3;
	case 0x3:
		return 0x2;
	case 0x2:
		return 0x0;
	default:
		return 0x0;
	}
}

void Randomize(void)
{
	timer timerSeed;
	UINT uintSeed;
	timerSeed :> uintSeed;

	// ������������� �� LFSR
	RNG_LFSR_G(uintSeed, 0x80000057);

	// ������������� �� ���������-�
	srand(uintSeed);
	for(int i = 0; i < NN_AM; i++)
	{
		uintDelay[i] = rand();
	}

	RNG_CRC32(uintSeed, 0xEB31D82E);
}

UINT RNG_LFSR_F(UINT uintSeed, UINT uintPoly)
{
	UINT uintMSB;
	UINT uintShiftRegCopy = uintShiftReg;

	if (uintSeed > 0)
		uintShiftReg = uintSeed;

#if (LFSR_F_VER == 1)
	uintMSB = (uintShiftReg >> 31) ^ (uintShiftReg >> 6) ^ (uintShiftReg >> 4)
			^ (uintShiftReg >> 2) ^ (uintShiftReg >> 1) ^ uintShiftReg;
#elif (LFSR_F_VER == 2)
	uintMSB = 0;

	for(int i = 0; i < (M - 1); i++)
	{
		if((uintPoly & 0x00000001) == 1)
			uintMSB ^= uintShiftRegCopy;

		par
		{
			uintShiftRegCopy >>= 1;
			uintPoly >>= 1;
		}
	}
#else
	#error INVALID LFSR_F_VER
#endif

	uintMSB = (uintMSB & 0x00000001) << 31;
	uintShiftReg = uintMSB | (uintShiftReg >> 1);

	return uintShiftReg & 0x00000001;
}

UINT RNG_LFSR_G(UINT uintSeed, UINT uintPoly)
{
	UINT uintResult;

	if (uintSeed > 0)
		uintShiftReg = uintSeed;

	if(uintShiftReg & 0x00000001)
	{
		uintShiftReg = 0x80000000 | ((uintShiftReg ^ uintPoly) >> 1);
		uintResult = 1;
	}
	else
	{
		uintShiftReg >>= 1;
		uintResult = 0;
	}

	return uintResult;
}

UINT RNG_ALG_M(UINT uintSeed, UINT uintPoly)
{
	UINT uintInx, uintRandomBit, uintResult;

	// ����������
	uintInx = 0;
	for(int i = 0; i < M; i++)
	{
		uintRandomBit = RNG_LFSR_F(0, 0x80000057);
		uintRandomBit = uintRandomBit << 31;
		uintInx = uintRandomBit | (uintInx >> 1);
	}

	uintInx = uintInx % NN_AM;
	uintResult = uintDelay[uintInx];
	uintDelay[uintInx] = rand();

	return uintResult;
}

UINT RNG_CRC32(UINT uintSeed, UINT uintPoly)
{
	if (uintSeed > 0)
		uintCRC32Reg = uintSeed;

	crc32(uintCRC32Reg, 0xFFFFFFFF, uintPoly);

	return uintCRC32Reg;
}

