/************************************************************************/
/*									*/
/*  OledDemo.pde -- Example OLED Sketch for chipKIT Basic I/O Shield	*/
/*									*/
/************************************************************************/
/*  Author:	Gene Apperson						*/
/*  Copyright (c) 2011, Digilent Inc.  	    			        */
/************************************************************************/
/*
  This program is free software; you can redistribute it and/or
  modify it under the terms of the GNU Lesser General Public
  License as published by the Free Software Foundation; either
  version 2.1 of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with this library; if not, write to the Free Software
  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*/
/************************************************************************/
/*  Module Description:							*/
/*									*/
/*  The sketch is an example program demonstrating the use of many of   */
/*  of the library functions used to access the OLED display on the     */
/*  Digilent chipKIT Basic I/O Shield.                                  */
/*									*/
/************************************************************************/
/*  Revision History:							*/
/*									*/
/*  08/24/2011(GeneApperson): Created                                   */
/*									*/
/************************************************************************/


/* ------------------------------------------------------------ */
/*		Include File Definitions			*/
/* ------------------------------------------------------------ */

#include <IOShieldOled.h>

#include <Wprogram.h>

/* ------------------------------------------------------------ */
/*		Local Type and Constant Definitions		*/
/* ------------------------------------------------------------ */

#define  OLED  IOShieldOledClass

#define cbOledChar      8                //number of bytes in a glyph
#define cbOledFontUser  (32*cbOledChar)  //number of bytes in user font table

/* ------------------------------------------------------------ */
/*		Global Variables				*/
/* ------------------------------------------------------------ */

OLED  oled;

/* ------------------------------------------------------------ */
/*		Local Variables					*/
/* ------------------------------------------------------------ */

/* Bitmap used by the putBmp function demonstration.
*/
uint8_t rgbBmp0[] = {
	0x81, 0x42, 0x24, 0x18, 0x18, 0x24, 0x42, 0x81,
	0x18, 0x24, 0x42, 0x81, 0x81, 0x42, 0x24, 0x18
};

/* Buffer to hold bitmap copied from the display in the getBmp
** demonstration.
*/
uint8_t rgbBmp1[32];

/* Array containing a user defined font table. There can be up
** to 32 user defined characters. This table only defines 24
** of them.
** Each 8-byte row below defines one character glyph.
*/
uint8_t rgbUserFont[cbOledFontUser] = {
	0x7E, 0x42, 0x42, 0x42, 0x42, 0x42, 0x42, 0x7E,	// 0x00
	0x81, 0x42, 0x24, 0x18, 0x18, 0x24, 0x42, 0x81,	// 0x01
	0x7E, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40,	// 0x02
	0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x7E,	// 0x03
	0x7E, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02,	// 0x04
	0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x7E,	// 0x05
	0x7E, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x7E,	// 0x06
	0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, 0xAA, 0x55, // 0x07
	0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80,	// 0x08
	0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40,	// 0x09
	0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, // 0x0A
	0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, // 0x0B
	0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, 0x08, // 0x0C
	0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, 0x04, // 0x0D
	0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02,	// 0x0E
	0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01,	// 0x0F
	0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,	// 0x10
	0x00, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,	// 0x11
	0x00, 0x00, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, // 0x12
	0x00, 0x00, 0x00, 0xFF, 0x00, 0x00, 0x00, 0x00, // 0x13
	0x00, 0x00, 0x00, 0x00, 0xFF, 0x00, 0x00, 0x00, // 0x14
	0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0x00, 0x00, // 0x15
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0x00,	// 0x16
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF	// 0x17
};


/* ------------------------------------------------------------ */
/*		Procedure Definitions				*/
/* ------------------------------------------------------------ */
/***  setup
**
**  Parameters:
**    none
**
**  Return Value:
**    none
**
**  Errors:
**    none
**
**  Description:
*/

void
setup() {
  char  ch;  

  /* Initialize the OLED display before access.
  */
  oled.begin();
  
  /* Define the user definable characters used in the demo.
  */
  for (ch = 0; ch < 0x18; ch++) {
    oled.defineUserChar(ch, &rgbUserFont[ch*cbOledChar]);
  }

}

/* ------------------------------------------------------------ */
/***  loop
**
**  Parameters:
**    none
**
**  Return Value:
**    none
**
**  Errors:
**    none
**
**  Description:
*/

void
loop() {

  drawBanner1();  
  delay(1000);
  
  drawSweepingLines();
  
  drawPixelDemo();
  delay(3000);
  
  drawLinePattern();
  delay(3000);
  
  fillRectDemo();
  
  drawRectDemo();
  delay(3000);
  
  putBmpDemo();
  
  putBmpEdgeTest();
  
  getBmpDemo();
  delay(2000);
  
  putStringDemo();
  delay(3000);
  
  putCharDemo();
  delay(3000);
  
  userCharDemo();
  delay(2000);
  
  graphicCharDemo();
  delay(2000);
  
}

/* ------------------------------------------------------------ */
/***  drawBanner1
**
**  Parameters:
**    none
**
**  Return Value:
**    none
**
**  Errors
**    none
**
**  Description:
**    Draw the banner display. This draws a line advancing down
**    the screen with the display text appearing as it goes down.
**    The screen is then blinked three times, and then a line
**    works its way back up the screen erasing the text as it
**    goes.
*/

void
drawBanner1() {
  
  int    row;

  /* Fill pattern 0 is all black
  */ 
  oled.setFillPattern(oled.getStdPattern(0));
  
  /* Drawing mode to set pixels to the current color value.
  */
  oled.setDrawMode(OLED::modeSet);
  
  /* Color 1 is the pixel illuminated.
  */
  oled.setDrawColor(1);
  
  /* Turn off automatic display update after putting text.
  */
  oled.setCharUpdate(false);
  
  /* Draw the banner text. The text is drawn slowly from the
  ** top down. This is done by filling the display buffer with
  ** the text and then using drawFillRect to erase part of it.
  ** The upper edge of the part being erased is gradually moved
  ** down the display from the top.
  */
  for (row = 0; row < OLED::rowMax; row++) {
    
    /* Fill the display buffer with the banner text.
    */
    oled.clearBuffer();
    oled.setCursor(0, 0);
    oled.putString("chipKIT");
    oled.setCursor(0, 1);
    oled.putString("Basic I/O Shield");
    oled.setCursor(0, 2);
    oled.putString("by Digilent");

    /* Erase everything below the current row and then draw
    ** a line across the display at the current row.
    */
    oled.moveTo(0, row);
    oled.drawFillRect(127,31);
    oled.moveTo(0,row);
    oled.drawLine(127,row);
    oled.updateDisplay();
    delay(100);
  }
  
  /* Clear the final line drawn.
  ** Draw color 0 is pixel not illuminated.
  */
  oled.setDrawColor(0);
  row -= 1;
  oled.moveTo(0, row);
  oled.drawLine(127, row);
  
  /* NOTE: Things don't show up on the display until
  ** updateDisplay is called (except for putChar and
  ** putString when auto update is enabled).
  */
  oled.updateDisplay();
  
  /* Blink the display.
  */
  delay(500);
  oled.displayOff();
  delay(500);
  oled.displayOn();
  delay(500);
  oled.displayOff();
  delay(500);
  oled.displayOn();
  delay(500);
  oled.displayOff();
  delay(500);
  oled.displayOn();
  delay(500);

  /* Let it show for a while so that it can be seen
  */
  delay(2000);

  /* Now erase the display. This is done by gradually
  ** erasing more and more of the text from the bottom up.
  ** This is done by drawing and erasing a line that
  ** gradually moves up the display.
  */
  oled.setDrawColor(1);
  
  for (row = OLED::rowMax-1; row >= 0; row--) {
    
    /* Draw a line across the current row.
    */
    oled.setDrawMode(OLED::modeSet);
    oled.moveTo(0,row);
    oled.drawLine(127,row);
    oled.updateDisplay();
    delay(25);
    
    /* Erase the line.
    */
    oled.setDrawMode(OLED::modeXor);
    oled.moveTo(0, row);
    oled.drawLine(127, row);
    oled.updateDisplay();
  }

  /* Restore the default auto update behavior
  ** for the putChar and putString.
  */
  oled.setCharUpdate(true);

}

/* ------------------------------------------------------------ */
/***  drawSweepingLines
**
**  Parameters:
**    none
**
**  Return Value:
**    none
**
**  Errors:
**    none
**
**  Description:
**    This illustrates a simple animation by drawing two vertical
**    lines that start at the center and then move out to the left
**    and right edges of the display and then back to the center.
*/

void
drawSweepingLines() {
  
  int    col;

  oled.setDrawColor(1);
  oled.setDrawMode(OLED::modeSet);

  for (col = 0; col < OLED::colMax/2; col++) {
    oled.clearBuffer();
    oled.moveTo(OLED::colMax/2 - col, 0);
    oled.drawLine(OLED::colMax/2 - col, OLED::rowMax-1);
    oled.moveTo(OLED::colMax/2 + col, 0);
    oled.drawLine(OLED::colMax/2 + col, OLED::rowMax-1);
    oled.updateDisplay();
    delay(10);
  }

  for (col = OLED::colMax/2; col >= 0; col--) {
    oled.clearBuffer();
    oled.moveTo(OLED::colMax/2 - col, 0);
    oled.drawLine(OLED::colMax/2 - col, OLED::rowMax-1);
    oled.moveTo(OLED::colMax/2 + col, 0);
    oled.drawLine(OLED::colMax/2 + col, OLED::rowMax-1);
    oled.updateDisplay();
    delay(10);
  }  
  
}

/* ------------------------------------------------------------ */
/***  drawPixelDemo
**
**  Parameters:
**    none
**
**  Return Value:
**    none
**
**  Errors:
**    none
**
**  Description:
**    This demonstrates using the drawPixel function. It draws
**    pairs of diagonal lines that end up creating a pattern
**    of X's on the display.
*/

void
drawPixelDemo() {
  
  int    col;
  int    row;
  
  oled.clearBuffer();
  
  for (col = 0; col < OLED::colMax; col++) {
    if (col < OLED::colMax/4) {
      /* If in left quarter of display, draw up and to
      ** the right.
      */
      row = col;
    }
    else if (col < OLED::colMax/2) {
      /* If in the second quarter of the display,
      ** draw up down and to the right.
      */
      row = 31 - (col & 0x1F);
    }
    else if (col < 3*OLED::colMax/4) {
      /* If in the third quarter of the display,
      ** draw down and to the right.
      */
      row = col & 0x1F;
    }
    else {
      /* If in the right quarter of the display,
      ** draw down and to the right.
      */
      row = 31 - (col & 0x1F);
    }
    
    /* Draw the pixel.
    */
    oled.moveTo(col, row);
    oled.drawPixel();
    
    if (col < OLED::colMax/4) {
      row = 31 - (col & 0x1F);
    }
    else if (col < 64) {
      row = col & 0x1F;
    }
    else if (col < 96) {
      row = 31 - (col & 0x1F);
    }
    else {
      row = col & 0x1F;
    }
    
    /* Draw the pixel.
    */
    oled.moveTo(col, row);
    oled.drawPixel();
  }
  
  /* Update the display so that we can see the result.
  */
  oled.updateDisplay();
}

/* ------------------------------------------------------------ */
/***  drawLinePattern
**
**  Parameters:
**    none
**
**  Return Value:
**    none
**
**  Errors:
**    none
**
**  Description:
**    This illustrates the use of the drawLine function. It draw a 
**    pattern of lines radiating out from the center of the display.
*/

void
drawLinePattern() {
  int    col;
  int    row;

  /* Clear the display buffer before drawing.
  */ 
  oled.clearBuffer();
  
  /* Draw a series of lines from the center of the display to
  ** points along the top.
  */
  for (col = 0; col < OLED::colMax; col += 16) {
    oled.moveTo(OLED::colMax/2, OLED::rowMax/2);
    oled.drawLine(col, 0);
  }

  /* Draw a series of lines from the center of the display to
  ** points along the right edge.
  */
  for (row = 0; row < OLED::rowMax; row += 8) {
    oled.moveTo(OLED::colMax/2, OLED::rowMax/2);
    oled.drawLine(OLED::colMax-1, row);
  }

  /* Draw a series of lines from the center of the display to
  ** points along the bottom.
  */
  for (col = 0; col < OLED::colMax; col += 16) {
    oled.moveTo(OLED::colMax/2, OLED::rowMax/2);
    oled.drawLine(col, OLED::rowMax-1);
  }

  /* Draw a series of lines from the center of the display to
  ** points along the left edge.
  */
  for (row = 0; row < OLED::rowMax; row += 8) {
    oled.moveTo(OLED::colMax/2, OLED::rowMax/2);
    oled.drawLine(0, row);
  }

  /* Update the display so that we can see the result.
  */
  oled.updateDisplay();

}

/* ------------------------------------------------------------ */
/***  fillRectDemo
**
**  Parameters:
**      none
**
**  Return Value:
**      none
**
**  Errors:
**      none
**
**  Description:
**    Illuarate drawing filled rectangles. This cycles through the
**    defined fill patterns drawing some rectangles. Note, that
**    the drawFillRect function doesn't draw the lines framing the
**    rectangle. That is done using drawRect.
*/

void
fillRectDemo() {
  int    ib;

  /* Cycle through the defined fill patterns.
  */  
  for (ib = 1; ib < 8; ib++) {
    /* Blank the display buffer before drawing this iteration
    */
    oled.clearBuffer();

    /* Select the fill pattern.
    */	
    oled.setFillPattern(oled.getStdPattern(ib));
    
    /* Draw some rectangles with fill.
    */
    oled.moveTo(5, 1);
    oled.drawFillRect(25, 5);
    oled.drawRect(25,5);
    oled.updateDisplay();
	
    oled.moveTo(30, 1);
    oled.drawFillRect(50,10);
    oled.drawRect(50,10);
    oled.updateDisplay();
	
    oled.moveTo(55, 1);
    oled.drawFillRect(75, 27);
    oled.drawRect(75,27);
    oled.updateDisplay();
	
    oled.moveTo(80, 8);
    oled.drawFillRect(105, 23);
    oled.drawRect(105,23);
    
    /* Update the display so that we can see the result.
    */
    oled.updateDisplay();
    
    delay(1000);
  }
}

/* ------------------------------------------------------------ */
/***  drawRectDemo
**
**  Parameters:
**    none
**
**  Return Value:
**    none
**
**  Errors:
**    none
**
**  Description:
**    Demonstrate drawing rectangles. This does a simple animiation
**    by drawing two pairs of rectangles that start at the left
**    and right sides of the display and move toward the center.
*/

void
drawRectDemo() {
    int    xco1;
    int    yco1;
    int    xco2;
    int    yco2;

  /* One pair of rectanges start at the left
  */  
  xco1 = 5;
  yco1 = 5;

  /* The other pair starts at the right.
  */
  xco2 = 122;
  yco2 = 26;

  while (xco1 < xco2) {
    /* Clear the buffer before drawing this frame of the
    ** animation.
    */
    oled.clearBuffer();

    /* Draw the two rectangels on the left.
    ** They are 15 pixels wide x 5 pixels high.
    */	
    oled.moveTo(xco1, yco1);
    oled.drawRect(xco1+15, yco1+5);
	
    oled.moveTo(xco1, yco2);
    oled.drawRect(xco1+15, yco2-5);

    /* Draw the two rectangles on the right.
    */	
    oled.moveTo(xco2, yco1);
    oled.drawRect(xco2-15, yco1+5);
	
    oled.moveTo(xco2, yco2);
    oled.drawRect(xco2-15, yco2-5);

    /* Update the display so we can see the result and
    ** then delay slightly so that the animation progresses
    ** at a reasonable pace.
    */	
    oled.updateDisplay();
    delay(10);

    /* Move toward the center of the display.
    */
    xco1 += 1;
    xco2 -= 1;
  }
  
}

/* ------------------------------------------------------------ */
/***  putBmpDemo
**
**  Parameters:
**    none
**
**  Return Value:
**    none
**
**  Errors:
**    none
**
**  Description:
**    Illustrate using the putBmp function to draw a bitmap on
**    the display. The bitmap is defined in the array rgbBmp0.
**    This also illustrates drawing only portions of the bitmap
**    by specifying different sizes to put.
**    The pattern of bitmaps is animated by moving down and to
**    the right until it reaches the bottom of the display and
**    then up and to the left.
*/

void
putBmpDemo() {
  int  yco;
  int  xco;

  /* Start at the top of the display.
  */  
  yco = 0;
  
  /* Increase X so that we move to the right.
  */
  for (xco = 0; xco < 30; xco++) {
    /* Clear the display buffer before drawing this iteration.
    */
    oled.clearBuffer();

    /* Do some putBmp calls to draw different portions
    ** of the bitmap spaced out to the right.
    */
    oled.moveTo(8+xco, yco);
    oled.putBmp(8, 4, rgbBmp0);

    oled.moveTo(18+xco, yco);
    oled.putBmp(8, 6, rgbBmp0);
	
    oled.moveTo(28+xco, yco);
    oled.putBmp(8, 8, rgbBmp0);
	
    oled.moveTo(38+xco, yco);
    oled.putBmp(8, 10, rgbBmp0);
	
    oled.moveTo(48+xco, yco);
    oled.putBmp(8, 12, rgbBmp0);

    oled.moveTo(58+xco, yco);
    oled.putBmp(8, 14, rgbBmp0);

    oled.moveTo(68+xco, yco);
    oled.putBmp(8, 16, rgbBmp0);

    /* Update the display so that we can see the result.
    */
    oled.updateDisplay();

    /* Move down for a while, and then move up.
    */
    if (xco <= 15) {
      yco += 1;
    }
    else {
      yco -= 1;
    }

    delay(100);
  }
}

/* ------------------------------------------------------------ */
/***  putBmpEdgeTest
**
**  Parameters:
**    none
**
**  Return Value:
**    none
**
**  Errors:
**    none
**
**  Description:
**    This illustrates clipping of bitmaps at the edges of the display
*/

void
putBmpEdgeTest() {
    int  xco;
    int  yco;

  /* Test moving the bitmap off the screen to the right.
  */
  for (xco = OLED::colMax-16; xco < OLED::colMax; xco++) {
    oled.clearBuffer();
    oled.moveTo(xco, 8);
    oled.putBmp(8, 16, rgbBmp0);
    oled.updateDisplay();
    delay(100);
  }

  /* Test moving the bitmap off the screen to the bottom.
  */
  for (yco = 8; yco < OLED::rowMax; yco++) {
    oled.clearBuffer();
    oled.moveTo(40, yco);
    oled.putBmp(8, 16, rgbBmp0);
    oled.updateDisplay();
    delay(100);
  }  
}

/* ------------------------------------------------------------ */
/***  getBmpDemo
**
**  Parameters:
**    none
**
**  Return Value:
**    none
**
**  Errors:
**    none
**
**  Description:
**    Demonstrate reading a bitmap off of the display, and then
**    writing it back to the display in another location.
*/

void
getBmpDemo() {
  int    ib;

  /* Clear the display buffer before we draw anything.
  */  
  oled.clearBuffer();
  
  /* Iterate down and to the right. This uses putBmp to write
  ** something into the display buffer. It then uses getBmp
  ** to read that portion of the display buffer, and then putBmp
  ** again to write what was read back to another place on the
  ** display.
  ** putBmp was used in this case to put something into the
  ** display buffer initially, but that is not a requirement.
  ** Any drawing functions can be used to write into the display
  ** before calling getBmp to read it into an offscreen bitmap.
  */
  for (ib = 0; ib < 8; ib++) {
    /* Write a pattern into the display.
    */
    oled.moveTo(8*ib+4, ib);
    oled.putBmp(8, 8, rgbBmp0);
    
    /* Read the pattern back into an offscreen bitmap.
    */
    oled.moveTo(8*ib+4, ib);
    oled.getBmp(8, 8, rgbBmp1);
    
    /* Write the offscreen bitmap back to another place on
    ** the display.
    */
    oled.moveTo(8*ib+4, 16+ib);
    oled.putBmp(8, 8, rgbBmp1);
    
    /* Update the display so that we can see the result.
    */
    oled.updateDisplay();
    delay(500);
  }
  
}

/* ------------------------------------------------------------ */
/***  putCharDemo
**
**  Parameters:
**    none
**
**  Return Value:
**    none
**
**  Errors:
**    none
**
**  Description:
**    Demonstrate using the putChar function to write ASCII
**    characters into the display.
**    Note: this example doesn't clear the display before
**    putting the characters. This means that the characters
**    put to the display will gradually write over what was
**    on the display when it began.
**    Note also that there are no calls to updateDisplay. The
**    character mode functions putChar and putString will
**    automatically update the display after each call.
**    This auto-update can be turned on or off using the
**    setCharUpdate.
**    Note also that the printing wraps when it gets to the
**    right side of the display. It will also wrap from the
**    bottom to the top.
*/

void
putCharDemo() {
  int    ib;

  /* Start at the upper left of the display.
  */  
  oled.setCursor(0, 0);
  
  /* Generate the printable ASCII characters in order.
  ** The printable characters start with 'A'.
  */
  for (ib = 0; ib < 64; ib ++) {
    oled.putChar('A'+ib);
    delay(100);
  }

}

/* ------------------------------------------------------------ */
/***  putStringDemo
**
**  Parameters:
**    none
**
**  Return Value:
**    none
**
**  Errors:
**    none
**
**  Description:
**    Demonstrate using setCursor and putString to write ASCII
**    character strings to the display.
**    Note that there are no calls to updateDisplay. The
**    character mode functions putChar and putString will
**    automatically update the display after each call.
**    This auto-update can be turned on or off using the
**    setCharUpdate.
*/

void
putStringDemo() {

  /* Clear the display. Note that clear has the same effect as
  ** calling clearBuffer and updateDisplay.
  */  
  oled.clear();

  /* Write some strings to the display.
  */
  oled.setCursor(0, 0);
  oled.putString("First Line");
  oled.setCursor(1, 1);
  oled.putString("Second Line");
  oled.setCursor(2, 2);
  oled.putString("Third Line");
  oled.setCursor(3, 3);
  oled.putString("Fourth Line");
  
}

/* ------------------------------------------------------------ */
/***  userCharDemo
**
**  Parameters:
**    none
**
**  Return Value:
**    none
**
**  Errors:
**    none
**
**  Description:
**    Demonstrate the use of user defined characters. The first
**    32 code values in the ASCII character are control characters
**    and don't have a defined glyph. In this library, those codes
**    are used for user defined characters. The code values for the
**    user defined characters are 0x00 through 0x1F (or 0 to 31 in
**    decimal). These can be written using any function that can be
**    used to write characters: (putChar, putString, drawChar, 
**    drawString).
**    The library was given the glyphs for the user defined character
**    set in the setup() function.
*/

void
userCharDemo() {
  int    ib;

  /* Clear the display.
  */  
  oled.clear();

  /* Write some regular text as a header on the first two lines.
  */
  oled.setCursor(0, 0);
  oled.putString("User Defined");
  oled.setCursor(0, 1);
  oled.putString("Characters");

  /* Write the user defined characters on the lower two lines.
  */
  oled.setCursor(0, 2);
  for (ib = 0; ib < 32; ib++) {
    oled.putChar(ib);
    delay(100);
  }

}

/* ------------------------------------------------------------ */
/***  graphicCharDemo
**
**  Parameters:
**    none
**
**  Return Value:
**    none
**
**  Errors:
**    none
**
**  Description:
**    Demonstrate drawing text as 'graphic characters'
**    The OLED display library supports two 'modes' of drawing text:
**    character mode and graphics mode. Strictly speaking, these
**    aren't really modes at all as call to the two styles of
**    character functions can be mixed at will.
**    The character functions (putChar, putString) use cursor
**    positions that are in terms of character column and character
**    row. These treat the display as if it were a 16x4 character
**    mode LCD display. the character mode functions also have the
**    auto-update behavior, so that the updateDisplay function
**    doesn't need to be called when using them.
**    The graphics functions (drawChar and drawString) use the
**    graphical coordinates and allow drawing characters at any
**    location on the display. The drawChar function is effectively
**    the same as putBmp where the bitmap is defined internally in
**    the library's character table. The grahics functions don't
**    automatically update the display.
*/

void
graphicCharDemo() {
  int  ib;
  int  xco1;
  int  yco1;
  int  xco2;
  int  yco2;
  
  xco1 = 0;
  yco1 = 0;
  xco2 = 64;
  yco2 = 23;

  /* Draw some text as a banner describing what is being
  ** demonstrated.
  */
  oled.clearBuffer();
  oled.moveTo(8, 8);
  oled.drawString("Graphic");
  oled.moveTo(32, 16);
  oled.drawString("Characters");
  oled.updateDisplay();
  
  /* Pause so that the user can see it.
  */
  delay(2000);

  /* Do a simple animation moving a couple of strings
  ** around on the display.
  */
  for (ib = 0; ib < 16; ib++) {
    oled.clearBuffer();
    oled.moveTo(xco1+ib, yco1+ib);
    oled.drawString("ABC");
    oled.moveTo(xco2-ib, yco2-ib);
    oled.drawString("DEF");
    oled.updateDisplay();
    delay(100);
  }
}

/* ------------------------------------------------------------ */

/************************************************************************/

  
  
  
