/************************************************************************/
/*																		*/
/*	OledDriver.h -- Interface Declarations for OLED Display Driver 		*/
/*																		*/
/************************************************************************/
/*	Author:		Gene Apperson											*/
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
/*  File Description:													*/
/*																		*/
/*	Interface to OledDriver.c											*/
/*																		*/
/************************************************************************/
/*  Revision History:													*/
/*																		*/
/*	04/29/2011(GeneA): created											*/
/*																		*/
/************************************************************************/

#if !defined(OLEDDRIVER_INC)
#define	OLEDDRIVER_INC

/* ------------------------------------------------------------ */
/*					Miscellaneous Declarations					*/
/* ------------------------------------------------------------ */

#define	cbOledDispMax	512		//max number of bytes in display buffer

#define	ccolOledMax		128		//number of display columns
#define	crowOledMax		32		//number of display rows
#define	cpagOledMax		4		//number of display memory pages

#define	cbOledChar		8		//font glyph definitions is 8 bytes long
#define	chOledUserMax	0x20	//number of character defs in user font table
#define	cbOledFontUser	(chOledUserMax*cbOledChar)

/* Graphics drawing modes.
*/
#define	modOledSet		0
#define	modOledOr		1
#define	modOledAnd		2
#define	modOledXor		3

/* ------------------------------------------------------------ */
/*					General Type Declarations					*/
/* ------------------------------------------------------------ */

/* Pin definitions for access to OLED control signals on ChipKitUno and ChipKitMax
*/
#if defined (_BOARD_UNO_) || defined(_BOARD_UC32_)
	#define	prtVddCtrl	IOPORT_F
	#define	prtVbatCtrl IOPORT_F
	#define	prtDataCmd	IOPORT_F
	#define	prtReset	IOPORT_G

	#define	bitVddCtrl	BIT_6
	#define	bitVbatCtrl	BIT_5
	#define bitDataCmd	BIT_4
	#define	bitReset	BIT_9
#elif defined (_BOARD_MEGA_)
	#define prtMosi		IOPORT_C
	#define prtMiso		IOPORT_A
	#define prtSck		IOPORT_A

	#define	prtVddCtrl	IOPORT_G
	#define	prtVbatCtrl IOPORT_G
	#define	prtDataCmd	IOPORT_G
	#define	prtReset	IOPORT_D

	#define bitMosi		BIT_4
	#define bitMiso		BIT_2
	#define bitSck		BIT_3

	#define	bitVddCtrl	BIT_14
	#define	bitVbatCtrl	BIT_13
	#define bitDataCmd	BIT_12
	#define	bitReset	BIT_4
#endif



/* ------------------------------------------------------------ */
/*					Object Class Declarations					*/
/* ------------------------------------------------------------ */



/* ------------------------------------------------------------ */
/*					Variable Declarations						*/
/* ------------------------------------------------------------ */



/* ------------------------------------------------------------ */
/*					Procedure Declarations						*/
/* ------------------------------------------------------------ */

void	OledInit();
void	OledTerm();
void	OledDisplayOn();
void	OledDisplayOff();
void	OledClear();
void	OledClearBuffer();
void	OledUpdate();

/* ------------------------------------------------------------ */

#endif

/************************************************************************/
