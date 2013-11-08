 Notes: 11/29/2012  this works.     
        12/07/2012  TX and RX working.
        02/21/2013  Dual band and some other stuff working

  Need to add 100/1khz/10khz flash and the band edge stop to an led.
  DONE: LED to stay lit at band edges.
  Add RIT routine limits.
  RIT range +/- 500 hz. This is subject to change! Top center of RIT pot 
  will have a dead band area of around 24. Analog ADC 1024 -24 = 1000/2 = 500 
  DONE: Add Band stop limits. 40m ( 7.000 > 7.300 ), 20m ( 14.000 > 14.350 )
  Main tuning steps 100 hz ( DEFAULT ).
  Default to the calling frequency of 40m and 20m. 40 ( 7.030 ), 20m ( 14.060 )
  Comment out the lcd routine later used for eval.
  This is real basic code to get things working. 
  Lets add the LCD Routine to show the Ref freq and the output freq
 *****************************************************************
  * LCD RS pin to digital pin 26
  * LCD Enable pin to digital pin 27
  * LCD D4 pin to digital pin 28
  * LCD D5 pin to digital pin 29
  * LCD D6 pin to digital pin 30
  * LCD D7 pin to digital pin 31
  * LCD R/W pin to ground
  * 10K resistor:
  * ends to +5V and ground
  * wiper to LCD VO pin (pin 3)    analogWrite(Side_Tone, 127);
 *****************************************************************
  Ideas on the Function and Select buttons.
  DONE: FUNCTION button steps from BW ( green ) to STEP ( yellow ) to OTHER (red ).
    SELECT button steps from in 
    BW ( <Wide, green>, <Medium, yellow>, <Narrow, red> ).
    STEP ( <100 hz, green, <1Khz, yellow>, 10Khz, red> ).
    OTHER ( < , >, < , >, < , > ) OTHER has yet to be defined

  Default Band_width will be wide ( Green led lite ).
  When pressing the function button one of three leds will lite. 
  as explained above the select button will choose which setting will be used. 
  The Orange led in the Ten-Tec logo will flash to each step the STEP is set 
  too when tuning.  As it will also turn on when at the BAND edges.  
  Default frequency on power up will be the calling frequency of either the 
  40 meter or 20 meter band. Which is selected by the band shorting block. 
  Pins shorted 40M
  Calling Frequency for 40 meters is 7.030 mhz.
  Calling Frequency for 20 meters is 14.060 mhz.
  I.F. Frequency used is 9.0 mhz.
  DDS Range is: 
  40 meters will use HI side injection.
  9(I.F.) + 7(40m) = 16mhz.  9(I.F.) + 7.30 = 16.3 mhz.
  20 meters will use LO side injection.
  14(20m) - 9(I.F.) = 5mhz.  14.350(20m) - 9(I.F.) = 5.35 mhz.

  The Headphone jack can supply a headphone or speaker. The header pins(2) 
  if shorted will drive a speaker.
  Unshorted inserts 100 ohm resistors in series with the headphone to limit 
  the level to the headphones.

  The RIT knob will be at 0 offset in the Top Dead Center position. And will 
  go about -500 hz to +500 hz when turned to either extreme. Total range 
  about +/- 500 hz. This may change!

  The band jumpers should be relocated when changing bans the TX low pass are 
  to one side or the other.  And the Receive filters are the same.
  made so changes to the BW control lines. need to rewrite so BW will 
  cycle according to the Function/Select idea.

  Added the Band_Stop and Flash led to the Schematic, need to write code to 
  reflect this.

  Thinking about using switch/case routines for the Function/Select. Also the 
  previous settings from BW/STEP/OTHER should be remembered when cycling 
  through the Function/Select routine. If any of this makes sense!

  As the code looks now I have more than likely left out several items!
  RIT is missing. Flash/Band edge is missing. Function/Select is missing. Etc.
  Need to update lcd only when encoder moved or buttons are pressed.
  
  March 19, 2013 got the function/select routines working. Now to copy the 
  code to this main program and get everything intergrated. Whew!!!!
  
  March 20, 2013. First day of Spring. Got the function/select routines 
  intergrated into program! Works!  Had to tweek on the delays a bit.  Still 
  need to tackle the DDS failure to come on without the encoder having to be 
  turned.
  Also need to get a routine that saves the current settings when powered down. 
  The list goes on and on!

  April 07, 2013. (AC7FK) Added serialDump routine to send information to host
  via the serial port (115200 bps).  The serialDump function is called once 
  per second.  Added calculation for loops per second and loop execution time.  
  Commented out the splash_RX_freq() function call to reduce execution time of 
  the main loop.  Simplifed IF frequency math by changing the sign of the IF
  based on the selected band at boot time.  General cleanup of whitespace
  and comments.
  
  
  April 11, 2013. (WA4CDM) Got the band edge led and frequency stops working.
  The Rebel will not operate out of Band now on RX or TX.
  Also got the RIT control separated from the TX frequency register.
  The Step_Flash routine works. Whenever the encoder is turned the led will flash.
  This will help to calculate the operating frequency when in 100 hz, 1khz or 10khz.
  
  April 23, 2013. Rit was looked into to remove the scratchy sound when Rit pot
  was turned. See the "void UpdateFreq(long freq)" routine.
  
  April 26, 2013. Modified Setup so the TX_OUT (Default_Settings) will be set to
  zero on power up. And set Band_End_Flash_led to zero.
  
  The pwm (Side_Tone 3) call was removed and that port was made to be a logic level.
  It will be used to provide an on/off signal for the hardware sidetone osc.
  
  May 1, 2013. (WA4CDM) Swapped the key lines in software. 
   TX_Dah  32    now  33
   TX_Dit  33    now  32
  
  May 15, 2013. (WA4CDM) This Rev(01) for posting on Yahoo users group.
  
  Release Date to Production 7/15/2013
 

  September 15, 2013 (KD8FJO) Added Optional feature selection.  Under Optional features uncomment the features you need. 
  Paul - KD8FJO


  September 15, 2013. (K4JK) Added simple IAMBIC keyer. Code adapted from openqrp.org.
  Speed can be changed by changing the argument to the loadWPM() function in setup().
  Mode set to IAMBICB by default.
  For comments or questions please use the Ten Tec yahoo group or email k4jk@arrl.net
  
  You can also use a straight key. Just connect it at startup and keyer routine will use this mode.
  
  You can also hold down either paddle lever at startup to enter straight key mode. This will
  allow you to emulate a straight key with one of the paddle levers.
  
  73, James - K4JK

  
  September 22, 2013. (PA3ANG) Added Beacon. Can be activated by entering U3 in USER menu. 
  Remember to adjust to the beacon frequency before.
  The beacon is activated by selecting U3 en leaving the USER menu!
  The beacon can be stopped by unselecting U3 during the delay.
  The speed and delay can be adjusted in the setup area.
  Make sure to change the beacon text before you compile.

   September 29, 2013. (KD8FJO) Added support for Nokia 5110 Display
   pin 30 - Serial clock out (SCLK)
   pin 29 - Serial data out (DIN)
   pin 28 - Data/Command select (D/C)
   pin 27 - LCD chip select (CS)
   pin 26 - LCD reset (RST)
