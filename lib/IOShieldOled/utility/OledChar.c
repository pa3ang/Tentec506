/************************************************************************/
/*																		*/
/*	OledChar.c	--	Character Output Routines for OLED Display			*/
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
/*	This module contains the implementations of the 'character mode'	*/
/*	functions. These functions treat the graphics display as a 4 row	*/
/*	by 16 column character display.										*/
/*																		*/
/************************************************************************/
/*  Revision History:													*/
/*																		*/
/*	06/01/2011(GeneA): created											*/
/*																		*/
/************************************************************************/


/* ------------------------------------------------------------ */
/*				Include File Definitions						*/
/* ------------------------------------------------------------ */

#include <p32xxxx.h>
#include <plib.h>

#include <inttypes.h>

#include "OledDriver.h"
#include "OledChar.h"
#include "OledGrph.h"

/* ------------------------------------------------------------ */
/*				Local Type Definitions							*/
/* ------------------------------------------------------------ */


/* ------------------------------------------------------------ */
/*				Global Variables								*/
/* ------------------------------------------------------------ */

extern int		xcoOledCur;
extern int		ycoOledCur;

extern BYTE *	pbOledCur;
extern BYTE		mskOledCur;
extern int		bnOledCur;
extern int		fOledCharUpdate;

extern BYTE		rgbOledBmp[];

extern int		dxcoOledFontCur;
extern int		dycoOledFontCur;

extern	BYTE *	pbOledFontCur;
extern	BYTE *	pbOledFontUser;

/* ------------------------------------------------------------ */
/*				Local Variables									*/
/* ------------------------------------------------------------ */

int		xchOledCur;
int		ychOledCur;

int		xchOledMax;
int		ychOledMax;

BYTE *	pbOledFontExt;

BYTE	rgbOledFontUser[cbOledFontUser];

/* ------------------------------------------------------------ */
/*				Forward Declarations							*/
/* ------------------------------------------------------------ */

void	OledDrawGlyph(char ch);
void	OledAdvanceCursor();

/* ------------------------------------------------------------ */
/*				Procedure Definitions							*/
/* ------------------------------------------------------------ */
/***	OledSetCursor
**
**	Parameters:
**		xch			- horizontal character position
**		ych			- vertical character position
**
**	Return Value:
**		none
**
**	Errors:
**		none
**
**	Description:
**		Set the character cursor position to the specified location.
**		If either the specified X or Y location is off the display, it
**		is clamped to be on the display.
*/

void
OledSetCursor(int xch, int ych)
	{

	/* Clamp the specified location to the display surface
	*/
	if (xch >= xchOledMax) {
		xch = xchOledMax-1;
	}

	if (ych >= ychOledMax) {
		ych = ychOledMax-1;
	}

	/* Save the given character location.
	*/
	xchOledCur = xch;
	ychOledCur = ych;

	/* Convert the character location to a frame buffer address.
	*/
	OledMoveTo(xch*dxcoOledFontCur, ych*dycoOledFontCur);

}

/* ------------------------------------------------------------ */
/***	OledGetCursor
**
**	Parameters:
**		pxch		- pointer to variable to receive horizontal position
**		pych		- pointer to variable to receive vertical position
**
**	Return Value:
**		none
**
**	Errors:
**		none
**
**	Description:
**		Fetch the current cursor position
*/

void
OledGetCursor( int * pxch, int * pych)
	{

	*pxch = xchOledCur;
	*pych = ychOledCur;

}

/* ------------------------------------------------------------ */
/***	OledDefUserChar
**
**	Parameters:
**		ch		- character code to define
**		pbDef	- definition for the character
**
**	Return Value:
**		none
**
**	Errors:
**		Returns TRUE if successful, FALSE if not
**
**	Description:
**		Give a definition for the glyph for the specified user
**		character code. User definable character codes are in
**		the range 0x00 - 0x1F. If the code specified by ch is
**		outside this range, the function returns false.
*/

int
OledDefUserChar(char ch, BYTE * pbDef)
	{
	BYTE *	pb;
	int		ib;

	if (ch < chOledUserMax) {
		pb = pbOledFontUser + ch * cbOledChar;
		for (ib = 0; ib < cbOledChar; ib++) {
			*pb++ = *pbDef++;
		}
		return 1;
	}
	else {
		return 0;
	}

	}

/* ------------------------------------------------------------ */
/***	OledSetCharUpdate
**
**	Parameters:
**		f		- enable/disable automatic update
**
**	Return Value:
**		none
**
**	Errors:
**		none
**
**	Description:
**		Set the character update mode. This determines whether
**		or not the display is automatically updated after a
**		character or string is drawn. A non-zero value turns
**		automatic updating on.
*/

void
OledSetCharUpdate(int f)
	{

	fOledCharUpdate = (f != 0) ? 1 : 0;

}

/* ------------------------------------------------------------ */
/***	OledGetCharUpdate
**
**	Parameters:
**		none
**
**	Return Value:
**		returns current character update mode
**
**	Errors:
**		none
**
**	Description:
**		Return the current character update mode.
*/

int
OledGetCharUpdate()
	{

	return fOledCharUpdate;

}

/* ------------------------------------------------------------ */
/***	OledPutChar
**
**	Parameters:
**		ch			- character to write to display
**
**	Return Value:
**		none
**
**	Errors:
**		none
**
**	Description:
**		Write the specified character to the display at the current
**		cursor position and advance the cursor.
*/

void
OledPutChar(char ch)
	{

	OledDrawGlyph(ch);
	OledAdvanceCursor();
	if (fOledCharUpdate) {
		OledUpdate();
	}

}

/* ------------------------------------------------------------ */
/***	OledPutString
**
**	Parameters:
**		sz		- pointer to the null terminated string
**
**	Return Value:
**		none
**
**	Errors:
**		none
**
**	Description:
**		Write the specified null terminated character string to the
**		display and advance the cursor.
*/

void
OledPutString(char * sz)
	{

	while (*sz != '\0') {
		OledDrawGlyph(*sz);
		OledAdvanceCursor();
		sz += 1;
	}

	if (fOledCharUpdate) {
		OledUpdate();
	}

}

/* ------------------------------------------------------------ */
/***	OledDrawGlyph
**
**	Parameters:
**		ch		- character code of character to draw
**
**	Return Value:
**		none
**
**	Errors:
**		none
**
**	Description:
**		Renders the specified character into the display buffer
**		at the current character cursor location. This does not
**		affect the current character cursor location or the 
**		current drawing position in the display buffer.
*/

void
OledDrawGlyph(char ch)
	{
	BYTE *	pbFont;
	BYTE *	pbBmp;
	int		ib;

	if ((ch & 0x80) != 0) {
		return;
	}

	if (ch < chOledUserMax) {
		pbFont = pbOledFontUser + ch*cbOledChar;
	}
	else if ((ch & 0x80) == 0) {
		pbFont = pbOledFontCur + (ch-chOledUserMax) * cbOledChar;
	}

	pbBmp = pbOledCur;

	for (ib = 0; ib < dxcoOledFontCur; ib++) {
		*pbBmp++ = *pbFont++;
	}

}

/* ------------------------------------------------------------ */
/***	OledAdvanceCursor
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
**		Advance the character cursor by one character location,
**		wrapping at the end of line and back to the top at the
**		end of the display.
*/

void
OledAdvanceCursor()
	{

	xchOledCur += 1;
	if (xchOledCur >= xchOledMax) {
		xchOledCur = 0;
		ychOledCur += 1;
	}
	if (ychOledCur >= ychOledMax) {
		ychOledCur = 0;
	}

	OledSetCursor(xchOledCur, ychOledCur);

}

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

