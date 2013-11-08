/************************************************************************/
/*																		*/
/*	OledDriver.c	-- Graphics Driver Library for OLED Display			*/
/*																		*/
/************************************************************************/
/*	Author: 	Gene Apperson											*/
/*	Copyright 2011, Digilent Inc.										*/
/************************************************************************/
/*
  This library is free software; you can redistribute it and/or
  modify it under the terms of the GNU Lesser General Public
  License as published by the Free Software Foundation; either
  version 2.1 of the License, or (at your option) any later version.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with this library; if not, write to the Free Software
  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*/
/************************************************************************/
/*  Module Description: 												*/
/*																		*/
/*	This is part of the device driver software for the OLED bit mapped	*/
/*	display on the Digilent Basic I/O Shield. This module contains the	*/
/*	initialization functions and basic display control functions.		*/
/*																		*/
/************************************************************************/
/*  Revision History:													*/
/*																		*/
/*	04/29/2011(GeneA): Created											*/
/*	08/03/2011(GeneA): added functions to shut down the display and to	*/
/*		turn the display on and off.									*/
/*	01/04/2012(GeneA): Changed use of DelayMs to using standard delay	*/
/*		function. Removed delay.h										*/
/*																		*/
/************************************************************************/


/* ------------------------------------------------------------ */
/*				Include File Definitions						*/
/* ------------------------------------------------------------ */

#include <WProgram.h>
#include <p32xxxx.h>
#include <plib.h>

#include "OledDriver.h"
#include "OledChar.h"
#include "OledGrph.h"

/* ------------------------------------------------------------ */
/*				Local Symbol Definitions						*/
/* ------------------------------------------------------------ */

#define	cmdOledDisplayOn	0xAF
#define	cmdOledDisplayOff	0xAE
#define	cmdOledSegRemap		0xA1	//map column 127 to SEG0
#define	cmdOledComDir		0xC8	//scan from COM[N-1] to COM0
#define	cmdOledComConfig	0xDA	//set COM hardware configuration

/* ------------------------------------------------------------ */
/*				Global Variables								*/
/* ------------------------------------------------------------ */

extern BYTE		rgbOledFont0[];
extern BYTE		rgbOledFontUser[];
extern BYTE		rgbFillPat[];

extern int		xchOledMax;
extern int		ychOledMax;

/* Coordinates of current pixel location on the display. The origin
** is at the upper left of the display. X increases to the right
** and y increases going down.
*/
int		xcoOledCur;
int		ycoOledCur;

BYTE *	pbOledCur;			//address of byte corresponding to current location
int		bnOledCur;			//bit number of bit corresponding to current location
BYTE	clrOledCur;			//drawing color to use
BYTE *	pbOledPatCur;		//current fill pattern
int		fOledCharUpdate;

int		dxcoOledFontCur;
int		dycoOledFontCur;

BYTE *	pbOledFontCur;
BYTE *	pbOledFontUser;

/* ------------------------------------------------------------ */
/*				Local Variables									*/
/* ------------------------------------------------------------ */

/* This array is the offscreen frame buffer used for rendering.
** It isn't possible to read back frome the OLED display device,
** so display data is rendered into this offscreen buffer and then
** copied to the display.
*/
BYTE	rgbOledBmp[cbOledDispMax];

/* ------------------------------------------------------------ */
/*				Forward Declarations							*/
/* ------------------------------------------------------------ */

void	OledHostInit();
void	OledHostTerm();
void	OledDevInit();
void	OledDevTerm();
void	OledDvrInit();

void	OledPutBuffer(int cb, BYTE * rgbTx);
BYTE	Spi2PutByte(BYTE bVal);

/* ------------------------------------------------------------ */
/*				Procedure Definitions							*/
/* ------------------------------------------------------------ */
/***	OledInit
**
**	Parameters:
**		none
**
**	Return Value:
**		none
**
**	Errors:
**		none
**
**	Description:
**		Initialize the OLED display subsystem.
*/

void
OledInit()
	{

	/* Init the PIC32 peripherals used to talk to the display.
	*/
	OledHostInit();

	/* Init the memory variables used to control access to the
	** display.
	*/
	OledDvrInit();

	/* Init the OLED display hardware.
	*/
	OledDevInit();

	/* Clear the display.
	*/
	OledClear();

}

/* ------------------------------------------------------------ */
/***	OledTerm
**
**	Parameters:
**		none
**
**	Return Value:
**		none
**
**	Errors:
**		none
**
**	Description:
**		Shut down the OLED display.
*/

void
OledTerm()
	{

	/* Shut down the OLED display hardware.
	*/
	OledDevTerm();

	/* Release the PIC32 peripherals being used.
	*/
	OledHostTerm();

}

/* ------------------------------------------------------------ */
/***	OledHostInit
**
**	Parameters:
**		none
**
**	Return Value:
**		none
**
**	Errors:
**		none
**
**	Description:
**		Perform PIC32 device initialization to prepare for use
**		of the OLED display.
**		This is currently hard coded for the Cerebot 32MX4 and
**		SPI2. This needs to be generalized.
*/

void
OledHostInit()
	{
	#if defined (_BOARD_UNO_) || defined(_BOARD_UC32_)
		/* Initialize SPI port 2.
		*/
		SPI2CON = 0;
		SPI2BRG = 4;				//8Mhz, with 80Mhz PB clock
		SPI2STATbits.SPIROV = 0;
		SPI2CONbits.CKP = 1;
		SPI2CONbits.MSTEN = 1;
		SPI2CONbits.ON = 1;
	#elif defined (_BOARD_MEGA_)
		/* Initialize pins for bit bang SPI. The Arduino Mega boards,
		** and therefore the Max32 don't have the SPI port on the same
		** connector pins as the Uno. The Basic I/O Shield doesn't even
		** connect to the pins where the SPI port is located. So, for
		** the Max32 board we need to do bit-banged SPI.
		*/
		PORTSetBits(prtSck, bitSck);
		PORTSetBits(prtMosi, bitMosi);
		PORTSetPinsDigitalOut(prtSck, bitSck);
		PORTSetPinsDigitalOut(prtMosi, bitMosi);
	#else
		#error "No Supported Board Defined"	
	#endif

	PORTSetBits(prtDataCmd, bitDataCmd);
	PORTSetBits(prtVddCtrl, bitVddCtrl);
	PORTSetBits(prtVbatCtrl, bitVbatCtrl);

	PORTSetPinsDigitalOut(prtDataCmd, bitDataCmd);		//Data/Command# select
	PORTSetPinsDigitalOut(prtVddCtrl, bitVddCtrl);		//VDD power control (1=off)
	PORTSetPinsDigitalOut(prtVbatCtrl, bitVbatCtrl);	//VBAT power control (1=off)

	/* Make the RG9 pin be an output. On the Basic I/O Shield, this pin
	** is tied to reset.
	*/
	PORTSetBits(prtReset, bitReset);
	PORTSetPinsDigitalOut(prtReset, bitReset);

}

/* ------------------------------------------------------------ */
/***	OledHostTerm
**
**	Parameters:
**		none
**
**	Return Value:
**		none
**
**	Errors:
**		none
**
**	Description:
**		Release processor resources used by the library
*/

void
OledHostTerm()
	{

	/* Make the Data/Command select, Reset, and SPI CS pins be inputs.
	*/
	PORTSetBits(prtDataCmd, bitDataCmd);
	PORTSetPinsDigitalIn(prtDataCmd, bitDataCmd);		//Data/Command# select
	PORTSetBits(prtReset, bitReset);
	PORTSetPinsDigitalIn(prtReset, bitReset);

	/* Make power control pins be inputs. The pullup resistors on the
	** board will ensure that the power supplies stay off.
	*/
	PORTSetBits(prtVddCtrl, bitVddCtrl);
	PORTSetBits(prtVbatCtrl, bitVbatCtrl);
	PORTSetPinsDigitalIn(prtVddCtrl, bitVddCtrl);		//VDD power control (1=off)
	PORTSetPinsDigitalIn(prtVbatCtrl, bitVbatCtrl);	//VBAT power control (1=off)

	/* Turn SPI port 2 off.
	*/
	#if defined (_BOARD_UNO_)
		SPI2CON = 0;
	#elif defined (_BOARD_MEGA_)
		PORTSetBits(prtSck, bitSck);
		PORTSetBits(prtMosi, bitMosi);
		PORTSetPinsDigitalIn(prtSck, bitSck);
		PORTSetPinsDigitalIn(prtMosi, bitMosi);
	#endif
}

/* ------------------------------------------------------------ */
/***	OledDvrInit
**
**	Parameters:
**		none
**
**	Return Value:
**		none
**
**	Errors:
**		none
**
**	Description:
**		Initialize the OLED software system
*/

void
OledDvrInit()
	{
	int		ib;

	/* Init the parameters for the default font
	*/
	dxcoOledFontCur = cbOledChar;
	dycoOledFontCur = 8;
	pbOledFontCur = rgbOledFont0;
	pbOledFontUser = rgbOledFontUser;

	for (ib = 0; ib < cbOledFontUser; ib++) {
		rgbOledFontUser[ib] = 0;
	}

	xchOledMax = ccolOledMax / dxcoOledFontCur;
	ychOledMax = crowOledMax / dycoOledFontCur;

	/* Set the default character cursor position.
	*/
	OledSetCursor(0, 0);

	/* Set the default foreground draw color and fill pattern
	*/
	clrOledCur = 0x01;
	pbOledPatCur = rgbFillPat;
	OledSetDrawMode(modOledSet);

	/* Default the character routines to automaticall
	** update the display.
	*/
	fOledCharUpdate = 1;

}

/* ------------------------------------------------------------ */
/***	OledDevInit
**
**	Parameters:
**		none
**
**	Return Value:
**		none
**
**	Errors:
**		none
**
**	Description:
**		Initialize the OLED display controller and turn the display on.
*/

void
OledDevInit()
	{

	/* We're going to be sending commands, so clear the Data/Cmd bit
	*/
	PORTClearBits(prtDataCmd, bitDataCmd);

	/* Start by turning VDD on and wait a while for the power to come up.
	*/
	PORTClearBits(prtVddCtrl, bitVddCtrl);
	delay(1);

	/* Display off command
	*/
	Spi2PutByte(cmdOledDisplayOff);

	/* Bring Reset low and then high
	*/
	PORTClearBits(prtReset, bitReset);
	delay(1);
	PORTSetBits(prtReset, bitReset);

	/* Send the Set Charge Pump and Set Pre-Charge Period commands
	*/
	Spi2PutByte(0x8D);		//From Univision data sheet, not in SSD1306 data sheet
	Spi2PutByte(0x14);

	Spi2PutByte(0xD9);		//From Univision data sheet, not in SSD1306 data sheet
	Spi2PutByte(0xF1);

	/* Turn on VCC and wait 100ms
	*/
	PORTClearBits(prtVbatCtrl, bitVbatCtrl);
	delay(100);

	/* Send the commands to invert the display.
	*/
	Spi2PutByte(cmdOledSegRemap);		//remap columns
	Spi2PutByte(cmdOledComDir);			//remap the rows

	/* Send the commands to select sequential COM configuration
	*/
	Spi2PutByte(cmdOledComConfig);		//set COM configuration command
	Spi2PutByte(0x20);					//sequential COM, left/right remap enabled

	/* Send Display On command
	*/
	Spi2PutByte(cmdOledDisplayOn);

}

/* ------------------------------------------------------------ */
/***	OledDevTerm
**
**	Parameters:
**		none
**
**	Return Value:
**		none
**
**	Errors:
**		none
**
**	Description:
**		Shut down the OLED display hardware
*/

void
OledDevTerm()
	{

	/* Send the Display Off command.
	*/
	Spi2PutByte(cmdOledDisplayOff);

	/* Turn off VCC
	*/
	PORTSetBits(prtVbatCtrl, bitVbatCtrl);
	delay(100);

	/* Turn off VDD
	*/
	PORTClearBits(prtVddCtrl, bitVddCtrl);

}

/* ------------------------------------------------------------ */
/***	OledDisplayOn
**
**	Parameters:
**		none
**
**	Return Value:
**		none
**
**	Errors:
**		none
**
**	Description:
**		Turn the display on. This assumes that the display has
**		already been powered on and initialized. All it does
**		is send the display on command.
*/

void
OledDisplayOn()
	{

	PORTClearBits(prtDataCmd, bitDataCmd);
	Spi2PutByte(cmdOledDisplayOn);

}

/* ------------------------------------------------------------ */
/***	OledDisplayOff
**
**	Parameters:
**		none
**
**	Return Value:
**		none
**
**	Errors:
**		none
**
**	Description:
**		Turn the display off. This does not power the display
**		down. All it does is send the display off command.
*/

void
OledDisplayOff()
	{

	PORTClearBits(prtDataCmd, bitDataCmd);
	Spi2PutByte(cmdOledDisplayOff);

}

/* ------------------------------------------------------------ */
/***	OledClear
**
**	Parameters:
**		none
**
**	Return Value:
**		none
**
**	Errors:
**		none
**
**	Description:
**		Clear the display. This clears the memory buffer and then
**		updates the display.
*/

void
OledClear()
	{

	OledClearBuffer();
	OledUpdate();

}

/* ------------------------------------------------------------ */
/***	OledClearBuffer
**
**	Parameters:
**		none
**
**	Return Value:
**		none
**
**	Errors:
**		none
**
**	Description:
**		Clear the display memory buffer.
*/

void
OledClearBuffer()
	{
	int			ib;
	BYTE *		pb;

	pb = rgbOledBmp;

	/* Fill the memory buffer with 0.
	*/
	for (ib = 0; ib < cbOledDispMax; ib++) {
		*pb++ = 0x00;
	}

}

/* ------------------------------------------------------------ */
/***	OledUpdate
**
**	Parameters:
**		none
**
**	Return Value:
**		none
**
**	Errors:
**		none
**
**	Description:
**		Update the OLED display with the contents of the memory buffer
*/

void
OledUpdate()
	{
	int		ipag;
	int		icol;
	BYTE *	pb;

	pb = rgbOledBmp;

	for (ipag = 0; ipag < cpagOledMax; ipag++) {

		PORTClearBits(prtDataCmd, bitDataCmd);

		/* Set the page address
		*/
		Spi2PutByte(0x22);		//Set page command
		Spi2PutByte(ipag);		//page number

		/* Start at the left column
		*/
		Spi2PutByte(0x00);		//set low nybble of column
		Spi2PutByte(0x10);		//set high nybble of column

		PORTSetBits(prtDataCmd, bitDataCmd);

		/* Copy this memory page of display data.
		*/
		OledPutBuffer(ccolOledMax, pb);
		pb += ccolOledMax;

	}

}

/* ------------------------------------------------------------ */
/***	OledPutBuffer
**
**	Parameters:
**		cb		- number of bytes to send/receive
**		rgbTx	- pointer to the buffer to send
**
**	Return Value:
**		none
**
**	Errors:
**		none
**
**	Description:
**		Send the bytes specified in rgbTx to the slave and return
**		the bytes read from the slave in rgbRx
*/
#if defined (_BOARD_UNO_) || defined(_BOARD_UC32_)
void
OledPutBuffer(int cb, BYTE * rgbTx)
	{
	int		ib;
	BYTE	bTmp;

	/* Write/Read the data
	*/
	for (ib = 0; ib < cb; ib++) {
		/* Wait for transmitter to be ready
		*/
		while (SPI2STATbits.SPITBE == 0);

		/* Write the next transmit byte.
		*/
		SPI2BUF = *rgbTx++;

		/* Wait for receive byte.
		*/
		while (SPI2STATbits.SPIRBF == 0);
		bTmp = SPI2BUF;

	}

}
#elif defined (_BOARD_MEGA_)
void
OledPutBuffer(int cb, BYTE * rgbTx)
	{
	int		ib;
	int		bit;
	BYTE	bVal;

	for(ib = 0; ib < cb; ib++) {	

		bVal = *rgbTx++;

		for(bit = 0; bit < 8;  bit++) {
			/* Check if MSB is 1 or 0 and set MOSI pin accordingly
			*/
			if(bVal & 0x80)
				PORTSetBits(prtMosi, bitMosi);
			else
				PORTClearBits(prtMosi, bitMosi);

			/* Lower the clock line
			*/
			PORTClearBits(prtSck, bitSck);

			/* Shift byte being sent to the left by 1
			*/
			bVal <<= 1;

			/* Raise the clock line
			*/
			PORTSetBits(prtSck, bitSck);
		}
	}
}
#endif

/* ------------------------------------------------------------ */
/***	Spi2PutByte
**
**	Parameters:
**		bVal		- byte value to write
**
**	Return Value:
**		Returns byte read
**
**	Errors:
**		none
**
**	Description:
**		Write/Read a byte on SPI port 2
*/
#if defined (_BOARD_UNO_) || defined(_BOARD_UC32_)
BYTE
Spi2PutByte(BYTE bVal)
	{
	BYTE	bRx;

	/* Wait for transmitter to be ready
	*/
	while (SPI2STATbits.SPITBE == 0);

	/* Write the next transmit byte.
	*/
	SPI2BUF = bVal;

	/* Wait for receive byte.
	*/
	while (SPI2STATbits.SPIRBF == 0);

	/* Put the received byte in the buffer.
	*/
	bRx = SPI2BUF;
	
	return bRx;

}
#elif defined (_BOARD_MEGA_)
BYTE
Spi2PutByte(BYTE bVal)
	{
	int		bit;
	BYTE	bRx;

	for(bit = 0; bit < 8;  bit++) {
		/* Check if MSB is 1 or 0 and set MOSI pin accordingly
		*/
		if(bVal & 0x80)
			PORTSetBits(prtMosi, bitMosi);
		else
			PORTClearBits(prtMosi, bitMosi);

		/* Lower the clock line
		*/
		PORTClearBits(prtSck, bitSck);

		/* Shift byte being sent to the left by 1
		*/
		bVal <<= 1;

		/* Raise the clock line
		*/
		PORTSetBits(prtSck, bitSck);
	}

	return bRx;
}
#endif

/* ------------------------------------------------------------ */
/***	ProcName
**
**	Parameters:
**
**	Return Value:
**
**	Errors:
**
**	Description:
**
*/

/* ------------------------------------------------------------ */

/************************************************************************/

