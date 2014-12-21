
/*
** RebelAllianceMod for the TenTec Rebel 506 QRP Tranceiver by PA3ANG
** This is a modified version of the code released by TenTec and the Rebel Alliance Mod V1.1. 
**
** FUNCTION AVAILABLE ARE: 
** BANDSWITCH - to disable comment the line #define FEATURE_BANDSWITCH. This function needs additional hardware!
** IAMBIC KEYER (A7 SPEED) - to disable set int ST_key = 1; Keyer setting IAMBICB and PDLSWAP changeble
** CQ message U2 - Please update message in line starting with #define CQ
** ANNOUNCE FREQ - Press SELECT longer then 0,5 seconds
** TUNE - 10 seconds carrier of less, function U3
** CAT - K3 emulation for VFO-A, Filter setting and S-meter reading
** TERMINAL - if no CAT is received the USB/Serial behaves as an output with 'display' data 
** NOKIA5110 DISPLAY - Standard display with LCD5110_Basic library ++ tentec.c bitmap changed by W2ROW
**
**  This library is free software; you can redistribute it and/or
** modify it under the terms of the GNU Lesser General Public
** License as published by the Free Software Foundation; either
** version 2.1 of the License, or (at your option) any later version.
** 
** This library is distributed in the hope that it will be useful,
** but WITHOUT ANY WARRANTY; without even the implied warranty of
** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
** Lesser General Public License for more details.
** 
** You should have received a copy of the GNU Lesser General Public
** License along with this library; if not, write to the Free Software
** Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
**
** Iambic Morse Code Keyer Sketch
** Copyright (c) 2009 Steven T. Elliott http://openqrp.org/?p=343
** 
*/

#include "TT506.h"                     // Ten-Tec Rebel model 506 definitions

// Analog pins
const int RitReadPin        = A0;      // pin that the sensor is attached to used for a rit routine later.
int RitReadValue            = 0;
int RitFreqOffset           = 0;

const int SmeterReadPin     = A1;      // To give a realitive signal strength based on AGC voltage.
const int PowerOutReadPin   = A3;      // Reads RF out voltage at Antenna.
int MeterReadValue          = 0;

const int BatteryReadPin    = A2;      // Reads 1/5 th or 0.20 of supply voltage.
float BatteryReadValue      = 0;
float BatteryVconvert       = 0.01707; //callibrated on 13.8v ps

const int CodeReadPin       = A6;      // Can be used to decode CW. 
int CodeReadValue           = 0;

const int CWSpeedReadPin    = A7;      // To adjust CW speed for user written keyer.
int CWSpeedReadValue        = 0;            


//-------------------------------  SET OPTONAL FEATURES HERE  -------------------------------------------------------------
int ST_key = 0;                    // Set this to 1 is you want to disable the keyer completely
int A7_adjust = 1;                 // Set this to 1 if you want to adjust the CW speed with pot A7, else the speed is 
                                   // controlled with function U1  DIT increase and DAH decrease speed.
#define FEATURE_BANDSWITCH         // Software based Band Switching.  Press FUNCTION > 0.5 seconds  NEEDS ADDITIONAL HARDWARE
                                   // Comment the line is you have no additional hardware added.
//-------------------------------  SET OPTONAL FEATURES HERE  -------------------------------------------------------------

//-------------------------------  CHANGE CALLSIGN HERE  -------------------------------------------------------------
#define     CQ              ("CQCQCQ DE PA3ANG PA3ANG PA3ANG K")     // CQ text 
//-------------------------------  CHANGE CALLSIGN HERE  -------------------------------------------------------------

// included in this sketch is a   
// Simple Arduino CW text Keyer for sending CQ by selecting U2
// which is also used for frequency announce by pressing the SELECT > 0.5 seconds
// Written by Mark VandeWettering K6HX
#define     CQ_DELAY        10                                 // in seconds
#define     N_MORSE  (sizeof(morsetab)/sizeof(morsetab[0]))    // Morse Table
// CQ function variables
unsigned long  cqStartTime    = 0;
unsigned long  cqElapsedTime  = 0;
#include "morse.h"

// Tune function variables
// this sketch let you key the tx for 10 seconds or less by selecting U3
unsigned long  tuneStartTime    = 0;
unsigned long  tuneElapsedTime  = 0;
int tune = 0;

//  keyerControl bit definitions
#define     DIT_L      0x01     // Dit latch
#define     DAH_L      0x02     // Dah latch
#define     DIT_PROC   0x04     // Dit is being processed

//-------------------------------  CHANGE KEYER SETTINGS HERE  -------------------------------------------------------------
#define     PDLSWAP    0x00     // 0x00 for normal, 0x08 for swap
#define     IAMBICB    0x10     // 0x00 for Iambic A, 0x10 for Iambic B
//-------------------------------  CHANGE KEYER SETTINGS HERE  -------------------------------------------------------------

//Keyer Variables
unsigned char       keyerControl;
unsigned char       keyerState;
unsigned long       ditTime;    // No. milliseconds per dit
enum KSTYPE {IDLE, CHK_DIT, CHK_DAH, KEYED_PREP, KEYED, INTER_ELEMENT };
int CWSpeed = 22;

// some text variables for the display and terminal functions
#define bw 3
String bwtext[bw] = { "W", "M", "N" };
#define stp 3
String steptext[stp] = {"100", "1K ", "10K"};
// define Display text constants		
const char txt0[7]          = "  2.3";
const char txt2[7]          = "Rebel";
const char txt73[7]         = "*TUNE*";
const char txt74[7]         = "TDELAY";
const char txt75[7]         = "CQCQCQ";
const char txt76[7]         = "CQDELY";
// load the NOKIA 5110 library  
#include <LCD5110_Basic.h>
// pin 30 - Serial clock out (SCLK)
// pin 29 - Serial data out (DIN)
// pin 28 - Data/Command select (D/C)
// pin 27 - LCD chip select (CS)
// pin 26 - LCD reset (RST)
LCD5110 myGLCD(30,29,28,26,27);
extern unsigned char SmallFont[];
extern unsigned char MediumNumbers[];
extern unsigned char BigNumbers[];
extern uint8_t tentec[];
extern uint8_t bit_map_1[];		// W2ROW bitmap addon
extern uint8_t bit_map_dot[];		// W2ROW bitmap addon
int rx_display;

// define terminal / cat active at start
int terminal = 1;                              // terminal active at start
String CatStatus = "T";
unsigned long  catStartTime    = 0;
unsigned long  catElapsedTime  = 0;
// stage buffer to avoid blocking on serial writes when using CAT
#define STQUESIZE 64
unsigned char stg_buf[STQUESIZE];
int stg_in = 0;
int stg_out = 0;

// bsm=0 is 40 meter, bsm=1 is 20 meter (original Rebel configuration)
int Band_bsm0_Low              = 7000000;
int Band_bsm0_High             = 7200000;
int Band_bsm1_Low              = 14000000;    
int Band_bsm1_High             = 14350000;

// various varibales
int TX_key;
int band_sel;                                   // select band 40 or 20 meter
int band_set;
int bsm                         = 0;  
int Step_Select_Button          = 0;
int Step_Select_Button1         = 0;
int Step_Multi_Function_Button  = 0;
int Step_Multi_Function_Button1 = 0;
int Selected_BW                 = 0;            // current Band width 
                                                // 0= wide, 1 = medium, 2= narrow
int Selected_Step               = 0;            // Current Step
int Selected_Other              = 0;            // To be used for anything

// Encoder Stuff 
const int encoder0PinA          = 7;
const int encoder0PinB          = 6;
int encoder0Pos                 = 0;
int encoder0PinALast            = LOW;
int encoder0PinBLast            = LOW;
int n                           = LOW;
int m                           = LOW;

// frequency vaiables and memory
const long meter_40             = 16.03e6;      // IF + Band frequency, 
long meter_40_memory            = 16.03e6;      // HI side injection 40 meter 
                                                // range 16 > 16.3 mhz                                              
const long meter_20             = 5.06e6;       // Band frequency - IF, LOW 
long meter_20_memory            = 5.06e6;       // side injection 20 meter 
                                                // range 5 > 5.35 mhz                                               
const long Reference            = 49.99975e6;   // for ad9834 this may be 
                                                // tweaked in software to 
                                                // fine tune the Radio

// variable to save the frequency at band switching
long RIT_frequency;
long RX_frequency;
long TX_frequency;
long save_rec_frequency;
long frequency_step;
long frequency                  = 0;
long frequency_old              = 0;
long frequency_tune             = 0;
long frequency_default          = 0;
long fcalc;
long IF                         = 9.00e6;        //  I.F. Frequency

// Timer variables for Debug and Display Refresh 
unsigned long loopCount         = 0;
unsigned long lastLoopCount     = 0;
unsigned long loopsPerSecond    = 0;
unsigned int  printCount        = 0;

unsigned long loopStartTime     = 0;
unsigned long loopElapsedTime   = 0;
float         loopSpeed         = 0;
unsigned long LastFreqWriteTime = 0;

//Program routines@
void Default_frequency();
void AD9834_init();
void AD9834_reset();
void program_freq0(long freq);
void program_freq1(long freq1);  // added 1 to freq
void UpdateFreq(long freq);
void led_on_off();
void Frequency_up();                        
void Frequency_down();                      
void TX_routine();
void RX_routine();
void Encoder();
void AD9834_reset_low();
void AD9834_reset_high();
void Band_Set_40M_20M();
void Band_40M_limits_led();
void Band_20M_limits_led();
void Step_Flash();
void RIT_Read();
void Multi_Function();          //
void Step_Selection();          // 
void Selection();               //
void Step_Multi_Function();     //

void MF_G();                    // Controls Function Green led
void MF_Y();                    // Controls Function Yellow led
void MF_R();                    // Controls Function Red led

void S_G();                     // Controls Selection Green led & 
                                // Band_Width wide, Step_Size 100, Other_1

void S_Y();                     // Controls Selection Green led & 
                                // Band_Width medium, Step_Size 1k, Other_2

void S_R();                     // Controls Selection Green led & 
                                // Band_Width narrow, Step_Size 10k, Other_3

void Band_Width_W();            //  A8+A9 low
void Band_Width_M();            //  A8 high, A9 low
void Band_Width_N();            //  A8 low, A9 high

void Step_Size_100();           //  100 hz step
void Step_Size_1k();            //  1 kilo-hz step
void Step_Size_10k();           //  10 kilo-hz step

void Other_1();                 //  user 1
void Other_2();                 //  user 2
void Other_3();                 //  user 3 

void clock_data_to_ad9834(unsigned int data_word);

// Setup and initialize 
void setup() 
{
  // these pins are for the AD9834 control
  pinMode(SCLK_BIT,               OUTPUT);    // clock
  pinMode(FSYNC_BIT,              OUTPUT);    // fsync
  pinMode(SDATA_BIT,              OUTPUT);    // data
  pinMode(RESET_BIT,              OUTPUT);    // reset
  pinMode(FREQ_REGISTER_BIT,      OUTPUT);    // freq register select

  //---------------  Encoder ------------------------------------
  pinMode (encoder0PinA,          INPUT);     // using optical for now
  pinMode (encoder0PinB,          INPUT);     // using optical for now 

  //---------------  Keyer --------------------------------------
  pinMode (TX_Dit,                INPUT);     // Dit Key line 
  pinMode (TX_Dah,                INPUT);     // Dah Key line
  pinMode (TX_OUT,                OUTPUT);
  pinMode (Band_End_Flash_led,    OUTPUT);
    
  //---------------- Menu leds ----------------------------------
  pinMode (Multi_function_Green,  OUTPUT);    // Band width
  pinMode (Multi_function_Yellow, OUTPUT);    // Step size
  pinMode (Multi_function_Red,    OUTPUT);    // Other
  pinMode (Multi_Function_Button, INPUT);     // Choose from Band width, Step size, Other

  //----------------- Selection leds ----------------------------
  pinMode (Select_Green,          OUTPUT);    //  BW wide, 100 hz step, other1
  pinMode (Select_Yellow,         OUTPUT);    //  BW medium, 1 khz step, other2
  pinMode (Select_Red,            OUTPUT);    //  BW narrow, 10 khz step, other3
  pinMode (Select_Button,         INPUT);     //  Selection form the above

  pinMode (Medium_A8,             OUTPUT);    // Hardware control of I.F. filter Bandwidth
  pinMode (Narrow_A9,             OUTPUT);    // Hardware control of I.F. filter Bandwidth
    
  pinMode (Side_Tone,             OUTPUT);    // sidetone enable
  
  Default_Settings();

  //---------------------------------------------------------------
  #ifndef FEATURE_BANDSWITCH
    pinMode (Band_Select,          INPUT);     // Band select via Jumpers.
  #endif

  #ifdef FEATURE_BANDSWITCH
    pinMode (Band_Select,         OUTPUT);    // Used to control relays connected to fileter lines.
    bsm = 0;                                    // default start is 40 meter 
    frequency = meter_20_memory;                // need to fool BANDSWITCH with 20 meter frequency 
                                                // if bsm = 1 (20 meter) then fool with meter_40_memory
  #endif

  AD9834_init();
  AD9834_reset();                               // low to high

  Band_Set_40_20M();
  Default_frequency();                          // what ever default is

  digitalWrite(TX_OUT,            LOW);         // turn off TX

  Step_Size_100();                              // Change for other Step_Size default!
  for (int i=0; i <= 5e4; i++);                 // small delay

  AD9834_init();
  AD9834_reset();
  encoder0PinALast = digitalRead(encoder0PinA);  
  attachCoreTimerService(TimerOverFlow);        //See function at the bottom of the file.

  myGLCD.InitLCD();
  myGLCD.setContrast(60);                       // Contrast 70 is medium 
  myGLCD.drawBitmap(0, 4, tentec, 84, 44);
  delay(1000);
  myGLCD.clrScr();

  Serial.begin(38400);                         // Enable serial port for terminal or cat

  keyerState   = IDLE;
  keyerControl = IAMBICB | PDLSWAP;
  if (A7_adjust)
    checkWPM();                                // Set CW Speed based on A7 pot
  else
    loadWPM(CWSpeed);
  
  //See if user wants to use a straight key because is he pressing the straight key or the 3,5 mm jack is short
  if ((digitalRead(TX_Dah) == LOW) || (digitalRead(TX_Dit) == LOW)) {    //Is a lever pressed?
    ST_key = 1;        //If so, enter straight key mode  
  }
}   //    end of setup


// Default settings 
void Default_Settings()
{
  digitalWrite(Multi_function_Green,  HIGH);   // Band_Width
  digitalWrite(Multi_function_Yellow, LOW);    //
  digitalWrite(Multi_function_Red,    LOW);    //
  digitalWrite(Select_Green,          LOW);    // Step 
  digitalWrite(Select_Yellow,         HIGH);   //
  Band_Width_M();                              // set M as startup default
  digitalWrite(Select_Green,          LOW);    //
  digitalWrite(TX_OUT,                LOW);    // TX off
  digitalWrite(FREQ_REGISTER_BIT,     LOW);    // This is set to LOW so RX is not dead on power on        
  digitalWrite(Band_End_Flash_led,    LOW);    // Led off
  digitalWrite(Side_Tone,             LOW);    // Tone off
}

//======================= Main Loop =================================
void loop()      
{
  digitalWrite(FSYNC_BIT,             HIGH);   
  digitalWrite(SCLK_BIT,              HIGH);   
  RIT_Read();
  Multi_Function(); 
  Encoder();

  if( !un_stage() ) Poll_Cat();                 // send data to CAT. If nothing to send, get next command.
  
  frequency_tune  = frequency + RitFreqOffset;
  UpdateFreq(frequency_tune);

  if ( A7_adjust ) checkWPM();
  if ( Selected_Other == 0 && Step_Multi_Function_Button1 == 2 && ST_key == 0 && !A7_adjust )    //U1 not Straight Key and not A7 adjust
    PaddleChangeWPM();      //Run Change Routine
  else
    TX_routine();
  
  if ( tune && ( millis() - tuneStartTime >= ( 10000 ) ) ) {
    // stop tune transmission 
    Step_Multi_Function_Button1 = 2;
    S_G();
    if ( !A7_adjust) Step_Multi_Function_Button1 = 0;    // if U1 meaningfull avoid this state
  }
  Tune();
  
  if ( Selected_Other == 1 ) 
  {
    cqElapsedTime = millis() - cqStartTime; 
    if( ( CQ_DELAY * 1000 ) <= cqElapsedTime ) // Wait delay seconds b4 and between sending CQ
    {
      NOKIA5110_Refresh(3);
      Terminal_Refresh(3); 
      sendmsg(CQ);
      cqStartTime = millis();                  // Reset the Timer for the beacon loop
    }
  }
  if ( Selected_Other == 2 && !tune ) 
  {
    tuneElapsedTime = millis() - tuneStartTime; 
    if( ( 1000 ) <= tuneElapsedTime )          // Wait 1 second b4 starting tune cycle
    {
      NOKIA5110_Refresh(2);
      Terminal_Refresh(2); 
      tune = 1;
      tuneStartTime = millis();                // Set the max Tune timer

    }
  }
  loopCount++;
  loopElapsedTime    = millis() - loopStartTime;    
  // has 500 milliseconds elasped?
  if( 500 <= loopElapsedTime )
    {
      NOKIA5110_Refresh(0); 
      Terminal_Refresh(0); 
      rx_display = 1;
      loopStartTime   = millis();
  }
}    
//=================== End Main Loop =================================


//------------------ Band Select ------------------------------------
#ifndef FEATURE_BANDSWITCH
  void Band_Set_40_20M()
  {
    bsm = digitalRead(Band_Select); 
    //  select 40 or 20 meters 1 for 20 0 for 40
    if ( bsm == 1 ) 
    { 
        frequency_default = meter_20;
    }
    else 
    { 
        frequency_default = meter_40; 
        IF *= -1;               //  HI side injection
    }

    Default_frequency();
  }
  #endif

//------------------ Software Band Select ------------------------------------
#ifdef FEATURE_BANDSWITCH
  void Band_Set_40_20M()
  {
    //  select 40 or 20 meters 1 for 20 0 for 40
    if ( bsm == 1 ) 
    { 
        meter_40_memory = frequency;
        frequency_default = meter_20_memory;
        if ( IF < 0 ) { IF *= -1; }
        digitalWrite(Band_Select,LOW);
    }
    else 
    { 
        meter_20_memory = frequency;
        frequency_default = meter_40_memory; 
        if ( IF > 0 ) { IF *= -1; }               //  HI side injection
        digitalWrite(Band_Select,HIGH);
    }
    Default_frequency();
    // flash Ten-Tec led
    for (int t=0; t < ((bsm-1)+2);) {
      Step_Flash(); 
      for (int i=0; i <= 200e3; i++); 
      t++;
    }
  }
#endif  //FEATURE_BANDSWITCH

//--------------------------- Encoder Routine ----------------------------  
// now we get 36 steps instead of 10 -- by Dana Conrad KD0UTH
void Encoder()
{
    n = digitalRead(encoder0PinA);
    m = digitalRead(encoder0PinB);

    if ((encoder0PinALast == LOW) && (n == HIGH))
    {
        if (m == LOW)
          Frequency_down();    //encoder0Pos--;
        else
          Frequency_up();       //encoder0Pos++;
    }
    else if ((encoder0PinALast == HIGH) && (n == LOW))
    {
        if (m == HIGH)
          Frequency_down();
        else
          Frequency_up();
    }
    else if ((encoder0PinBLast == LOW) && (m == HIGH))
    {
        if (n == LOW)
          Frequency_up();
        else
          Frequency_down();
    }
    else if ((encoder0PinBLast == HIGH) && (m == LOW))
    {
        if (n == HIGH)
          Frequency_up();
        else
          Frequency_down();
    }
    encoder0PinALast = n;
    encoder0PinBLast = m;
}

//----------------------------------------------------------------------
void Frequency_up()
{ 
    frequency = frequency + frequency_step;
    
    Step_Flash();
    
#ifndef FEATURE_BANDSWITCH
    bsm = digitalRead(Band_Select); 
#endif

     if ( bsm == 1 ) { Band_20_Limit_High(); }
     else if ( bsm == 0 ) {  Band_40_Limit_High(); }
 
}

//------------------------------------------------------------------------------  
void Frequency_down()
{ 
    frequency = frequency - frequency_step;
    
    Step_Flash();
    
#ifndef FEATURE_BANDSWITCH
    bsm = digitalRead(Band_Select); 
#endif

     if ( bsm == 1 ) { Band_20_Limit_Low(); }
     else if ( bsm == 0 ) {  Band_40_Limit_Low(); }
 
}
//-------------------------------------------------------------------------------
void UpdateFreq(long freq)
{
    long freq1;
    //  some of this code affects the way to Rit responds to being turned
    if (LastFreqWriteTime != 0)
    { if ((millis() - LastFreqWriteTime) < 100) return; }
    LastFreqWriteTime = millis();

    if(freq == frequency_old) return;
    //if( keyerState != IDLE ) return;    //  <---   Add this

    program_freq0( freq  );
            
    #ifndef FEATURE_BANDSWITCH
      bsm = digitalRead(Band_Select); 
    #endif
    
    freq1 = freq - RitFreqOffset;  //  to get the TX freq

    program_freq1( freq1 + IF  );
  
    frequency_old = freq;
}

//---------------------  TX Routines  ------------------------------------------------  
void TX_on(){
      digitalWrite(FREQ_REGISTER_BIT, HIGH);
      digitalWrite(TX_OUT, HIGH);
      digitalWrite(Side_Tone, HIGH);
}
void TX_off(){
      digitalWrite(TX_OUT, LOW);                        // turn off TX
      for (int i=0; i <= 10e3; i++);  // delay for maybe some decay on key release
      digitalWrite(FREQ_REGISTER_BIT, LOW);
      digitalWrite(Side_Tone, LOW);
}

void Tune()
{
  switch ( tune )         // start TX   
    {
      case 1:
        TX_on();
        if ( rx_display )                      // flag indicating display switch from RX to TX
        {
        NOKIA5110_Refresh(1);
        Terminal_Refresh(1);
        rx_display = 0;
        }
      break;
      
      case 2:
        TX_off();
        tune = 0;
      break;
      
    }
}

void TX_routine()
{
  if ( ST_key ) {      // is ST_Key is set to YES? Then use Straight key mode
                       // Will detect straight key at startup.
    TX_key = digitalRead(TX_Dit);
    if ( TX_key == LOW)         // was high   
    {
        do
        {
            TX_on();
            if ( rx_display )             // flag indicating display switch from RX to TX
            {
              NOKIA5110_Refresh(1);
              Terminal_Refresh(1);
              rx_display = 0;
            }
            TX_key = digitalRead(TX_Dit);
        } while (TX_key == LOW);         // was high 

        TX_off();
        loopStartTime = millis();       //Reset the Timer for this loop
    }
  } 
  else
  {                     //If ST_key is not 1, then use IAMBIC
    static long ktimer;
    // Basic Iambic Keyer
    // keyerControl contains processing flags and keyer mode bits
    // Supports Iambic A and B
    // State machine based, uses calls to millis() for timing.
    // Code adapted from openqrp.org
    switch (keyerState) {
    case IDLE:
        // Wait for direct or latched paddle press
        if ((digitalRead(TX_Dit) == LOW) || (digitalRead(TX_Dah) == LOW) || (keyerControl & 0x03)) {
            update_PaddleLatch();
            keyerState = CHK_DIT;
        }
        break;

    case CHK_DIT:
        // See if the dit paddle was pressed
        if (keyerControl & DIT_L) {
            keyerControl |= DIT_PROC;
            ktimer = ditTime;
            keyerState = KEYED_PREP;
        }
        else {
            keyerState = CHK_DAH;
        }
        break;
        
    case CHK_DAH:
        // See if dah paddle was pressed
        if (keyerControl & DAH_L) {
            ktimer = ditTime*3;
            keyerState = KEYED_PREP;
        }
        else {
            keyerState = IDLE;
        }
        break;
        
    case KEYED_PREP:
        // Assert key down, start timing, state shared for dit or dah
        TX_on();        
        ktimer += millis();                   // set ktimer to interval end time
        keyerControl &= ~(DIT_L + DAH_L);     // clear both paddle latch bits
        keyerState = KEYED;                   // next state
        break;
        
    case KEYED:
        // Wait for timer to expire
        if ( rx_display )                      // flag indicating display switch from RX to TX
       {
          NOKIA5110_Refresh(1);
          Terminal_Refresh(1);
          rx_display = 0;
        }
        if (millis() > ktimer) {              // are we at end of key down ?
            TX_off();
            ktimer = millis() + ditTime;      // inter-element time
            keyerState = INTER_ELEMENT;       // next state
            loopStartTime = millis();         // Reset display Timer to keep CW clean

        }
        else if (keyerControl & IAMBICB) {
            update_PaddleLatch();             // early paddle latch in Iambic B mode
        }
        break; 
 
    case INTER_ELEMENT:
        // Insert time between dits/dahs
        update_PaddleLatch();                 // latch paddle state
        if (millis() > ktimer) {              // are we at end of inter-space ?
            if (keyerControl & DIT_PROC) {    // was it a dit or dah ?
                keyerControl &= ~(DIT_L + DIT_PROC);   // clear two bits
                keyerState = CHK_DAH;         // dit done, check for dah
            }
            else {
                keyerControl &= ~(DAH_L);     // clear dah latch
                keyerState = IDLE;            // go idle
                loopStartTime = millis();     // Reset display Timer to keep CW clean
            }
        }
        break;
    }
  }
}

//    Latch dit and/or dah press, called by de keyer routine and checking PDLSWAP!
void update_PaddleLatch(){
  if (digitalRead(TX_Dit) == LOW) {
      if (keyerControl & PDLSWAP) keyerControl |= DAH_L; else keyerControl |= DIT_L;
  }
  if (digitalRead(TX_Dah) == LOW) {
      if (keyerControl & PDLSWAP) keyerControl |= DIT_L; else keyerControl |= DAH_L;
  }
}

// Calculate new time constants based on wpm value
void loadWPM(int wpm){
  ditTime = 1200/(wpm+3);              // correction factor = 3
}

// Checks the Keyer speed Pot and updates value 
void checkWPM(){
  CWSpeedReadValue = analogRead(CWSpeedReadPin);
  CWSpeedReadValue = map(CWSpeedReadValue, 0, 1024, 5, 45);
  loadWPM(CWSpeedReadValue);
  CWSpeed = CWSpeedReadValue;
}

//Routine to change CW speed when User mode option #1 is selected. Dit will increase speed, dah will decrease. 
//Either can be held down for rapid change. This is called from main loop() function.
void PaddleChangeWPM()                                
{
  if (digitalRead(TX_Dit) == LOW)      //Dit?
  {
    CWSpeed ++;                        //Increase
    digitalWrite(Side_Tone, HIGH);     //Some side tone to let user know it's working
    delay(ditTime);                    //Make dit length normal
    digitalWrite(Side_Tone, LOW);      //Stop tone
    loadWPM(CWSpeed);                  //Call function that updates key speed
    delay(ditTime * 3);                //Delay between elements in case key is held down
  }
  else if (digitalRead(TX_Dah) == LOW) //Dah?
  {
    CWSpeed --;                        //Decrease
    digitalWrite(Side_Tone, HIGH);     //Some side tone to let user know it's working
    delay(ditTime * 3);                //Make dah length normal
    digitalWrite(Side_Tone, LOW);      //Stop tone
    loadWPM(CWSpeed);                  //Call function that updates key speed
    delay(ditTime * 3);                //Delay between elements in case key is held down
  }
}

// CW generation routines for CQ message 
void key(int LENGTH){
  TX_on();
  delay(LENGTH);
  TX_off();
  delay(ditTime) ;
}

void send(char c){
  int i ;
  if (c == ' ') {
    delay(7*ditTime) ;
    return ;
  }
  for (i=0; i<N_MORSE; i++){
    if (morsetab[i].c == c){
      unsigned char p = morsetab[i].pat ;
      while (p != 1) {
        if (p & 1)
          key(ditTime*3) ;
        else
          key(ditTime) ;
          p = p / 2 ;
      }
      delay(ditTime*3) ;
      return ;
      }
  }
}

void sendmsg(char *str){
  while (*str) {
    if (digitalRead(TX_Dit) == LOW || digitalRead(TX_Dah) == LOW ) 
    {
      // stop automatic transmission CQ
      Step_Multi_Function_Button1 = 2;
      S_G();
      if ( !A7_adjust) Step_Multi_Function_Button1 = 0;  // if U1 meaningfull avoid this state
      return;
    }
    Selection();
    if ( Selected_Other != Other_2_user ) 
    {
      // stop automatic transmission CQ
      Step_Multi_Function_Button1 = 2;
      S_G();
      if ( !A7_adjust) Step_Multi_Function_Button1 = 0;  // if U1 meaningfull avoid this state
      return;
    }
    send(*str++) ;
  }  
}

// More then 0.5 second SELECT is Freq Announce
void announce(char *str){
  while (*str) 
    key_announce(*str++); 
}

void beep(int LENGTH) {
  digitalWrite(Side_Tone, HIGH);
  delay(LENGTH);
  for (int i=0; i <= 10e3; i++);       // delay to equel with TX speed
  digitalWrite(Side_Tone, LOW);
  delay(ditTime) ;
}

void key_announce(char c){
  for (int i=0; i<N_MORSE; i++) {
    if (morsetab[i].c == c) {
      unsigned char p = morsetab[i].pat ;
      while (p != 1) {
        if (p & 1)
          beep(ditTime*3) ;
        else
          beep(ditTime) ;
          p = p / 2 ;
      }
      delay(ditTime*3) ;
      return ;
      }
  }
}

// RIT routine  
void RIT_Read(){
  int RitReadValueNew =0 ;
  RitReadValueNew = analogRead(RitReadPin);
  RitReadValue = (RitReadValueNew + (7 * RitReadValue))/8;//Lowpass filter

  if(RitReadValue < 500) 
      RitFreqOffset = RitReadValue-500;
  else if(RitReadValue < 523) 
      RitFreqOffset = 0;//Deadband in middle of pot
  else 
      RitFreqOffset = RitReadValue - 523;
}

// Check Limits
void  Band_40_Limit_High(){
  if ( frequency < 16.3e6 ) stop_led_off();
  else if ( frequency >= 16.3e6 ) { 
    frequency = 16.3e6;
    stop_led_on();    
  }
}
 
void  Band_40_Limit_Low(){
  if ( frequency <= 16.0e6 ) {
    frequency = 16.0e6;
    stop_led_on();
  } 
  else if ( frequency > 16.0e6 ) stop_led_off(); 
}
   
void  Band_20_Limit_High(){
  if ( frequency < 5.35e6 ) stop_led_off();
  else if ( frequency >= 5.35e6 ) { 
    frequency = 5.35e6;
    stop_led_on();    
  }
}

void  Band_20_Limit_Low(){
  if ( frequency <= 5.0e6 ) {
    frequency = 5.0e6;
    stop_led_on();
  } 
  else if ( frequency > 5.0e6 ) stop_led_off(); 
}

// Frequency set routines
void Default_frequency(){
  frequency = frequency_default;
  UpdateFreq(frequency);
}

//------------------------CAT Routine based on Elecraft K3 -------------------------------
//   some general routines for serial printing

int un_stage(){              // send a char on serial 
char c;
   if( stg_in == stg_out ) return 0;
   c = stg_buf[stg_out++];
   stg_out &= ( STQUESIZE - 1);
   Serial.write(c);
   return 1;
}
void stage( unsigned char c ){
  stg_buf[stg_in++] = c;
  stg_in &= ( STQUESIZE - 1 );
}
void stage_str( String st ){
int i;
char c;
  for( i = 0; i < st.length(); ++i ){
     c= st.charAt( i );
     stage(c);
  }    
}
void stage_num( int val ){   // send number in ascii 
char buf[12];
char c;
int i;
   itoa( val, buf, 10 );
   i= 0;
   while( c = buf[i++] ) stage(c);  
}

void Poll_Cat() {
static String command = "";
String lcommand;
char c;
int rit;

    if (Serial.available() == 0) return;
    
    while( Serial.available() ){
       c = Serial.read();
       command += c;
       if( c == ';' ) break;
    }
    
    if( c != ';' ) { terminal = 0; CatStatus = "C"; return; }   // command not complete yet but need to switch of terminal
  
    lcommand = command.substring(0,2);
 
    if( command.substring(2,3) == ";" || command.substring(2,4) == "$;" || command.substring(0,2) == "RV" ){      /* it is a get command */
      stage_str(lcommand);    // echo the command 
      if( command.substring(2,3) == "$") stage('$');
      
      if (lcommand == "IF") {
        RX_frequency = frequency + IF;
        stage_str("000");
        if( RX_frequency < 10000000 ) stage('0');
        stage_num(RX_frequency);  
        stage_str("     ");
        rit= RitFreqOffset;
        if( rit >= 0 ) stage_str("+0");
        else{
          stage_str("-0"); 
          rit = - rit;
        }
        if( rit < 100 ) stage('0');
        if( rit < 10 ) stage('0');                                  // IF[f]*****+yyyyrx*00tmvspbd1*;
        stage_num(rit);
        stage_str("10 0003000001");                                 // rit,xit,xmit,cw mode fixed filed 
      }
      else if(lcommand == "FA") {                                   // VFO A
        stage_str("000"); 
        if( frequency + IF < 10000000 ) stage('0');  
        stage_num(frequency + IF);  
      } 
      else if(lcommand == "KS") stage_num(CWSpeed);                // KEYER SPEED
      else if(lcommand == "FW") stage_str("0000") , stage_num(Selected_BW+1);
      else if(lcommand == "MD") stage('3');                        // Mode CW
      
      else if(lcommand == "RV" && command.substring(2,3) == "F"){  // battery voltage in Front field 
        stage(command.charAt(2));
        double value = analogRead(BatteryReadPin)* BatteryVconvert;
        int left_part, right_part;
        char buffer[50];
        sprintf(buffer, "%lf", value);
        sscanf(buffer, "%d.%1d", &left_part, &right_part);
        stage(' ');
        stage_num(left_part);
        stage('.');
        stage_num(right_part);
        stage(' ');
     }
      else if(lcommand == "RV" && command.substring(2,3) == "A"){  // Rebel Alliance Mod version in Aux: field
        stage(command.charAt(2));
        stage_str(txt0);
      }
      else if(lcommand == "RV" && command.substring(2,3) == "D"){  // Rebel Alliance Mod in DSP: field   
        stage(command.charAt(2));
        stage_str(txt2);
      }
      else if(lcommand == "RV" && command.substring(2,3) == "M"){  // Keyer Speed in MCU: field
        stage(command.charAt(2));
        stage_num(CWSpeed);
      }
      else if(lcommand == "RV" && command.substring(2,3) == "R"){  // Keyer Speed in MCU: field
        stage(command.charAt(2));
        stage_str(steptext[Selected_Step]);
      }
      else if(lcommand == "SM"){
        stage_str("00");
        MeterReadValue = analogRead(SmeterReadPin);
        MeterReadValue = map(MeterReadValue, 0, 170, 0, 11);
        if( MeterReadValue < 10 ) stage('0');
        stage_num(MeterReadValue);
      }   
      else {
        stage('0');   // send back nill command not know / used
      }
    stage(';');       // response terminator 
    }
 
    else  {} set_cat(lcommand,command);    // else it's a set command 
   
    command = "";   // clear for next command
}

void set_cat(String lcom, String com ){
long value;
int split =0 ;
 
    if( lcom == "FA" ){    // set vfo freq 
      value = com.substring(2,13).toInt(); 
      #ifndef FEATURE_BANDSWITCH
        if ( ((value > Band_bsm0_Low && value < Band_bsm0_High) && bsm == 0) || ((value > Band_bsm1_Low && value < Band_bsm1_High) && bsm == 1) ) {
          // can I change the frequency according to the band setting / configuration
      #endif
      #ifdef FEATURE_BANDSWITCH
        if ( (value > Band_bsm0_Low && value < Band_bsm0_High) || (value > Band_bsm1_Low && value < Band_bsm1_High)  ) {
          // valid frequnecy according Rebel band configuration?
          if ( (value > Band_bsm0_Low && value < Band_bsm0_High) && bsm == 1) {
          // need to change band?
            bsm = 0;
            Band_Set_40_20M();
          }
          if ( (value > Band_bsm1_Low && value < Band_bsm1_High) && bsm == 0) {
          // need to change band?
            bsm = 1;
            Band_Set_40_20M();
          }   
        #endif
        //if( lcom == "FB" || split == 0 ) frequency = value - IF;
        if( lcom == "FA" && ( value > 1800000 && value < 30000000) ) frequency = value - IF;
        }
    }
    else if( lcom == "FW" ){             // xtal filter select
      value = com.charAt(6) - '0';
      if( value < 4 && value != 0 ){
        if ( value == 1) Band_Width_W();
        if ( value == 2) Band_Width_M();
        if ( value == 3) Band_Width_N();
      }
    }
}

//------------------------Display Stuff below-----------------------------------

void NOKIA5110_Refresh(int z)  
  {
    long int f1, f2;
    
    myGLCD.print(txt2,0,0); 
    
    RX_frequency = frequency_tune + IF;
    TX_frequency = frequency + IF;

    myGLCD.clrRow(1);
    myGLCD.setFont(MediumNumbers);
    
    if ( !z ) {	
      f1 = RX_frequency/1000000;
      if (f1 > 9)
      {
        myGLCD.drawBitmap(1, 16, bit_map_1, 4, 16); 
        myGLCD.printNumI(f1-10, 4, 16, 1, '0');
      }
      else
        myGLCD.printNumI(f1, 4, 16, 1); 
      f2 = RX_frequency/1000 - f1*1000;
      
      myGLCD.printNumI(f2, 20, 16, 3, '0');
      myGLCD.printNumI((RX_frequency - f1*1000000 - f2*1000)/10, 60, 16, 2, '0');
      myGLCD.drawBitmap(17, 24, bit_map_dot, 2, 8); 
      myGLCD.drawBitmap(57, 24, bit_map_dot, 2, 8);

      myGLCD.setFont(SmallFont);
      myGLCD.clrRow(0, 42);
      if ( RitFreqOffset != 0) {
        myGLCD.printNumI(RitFreqOffset, RIGHT, 0);
      }
    }
    else
    {
      f1 = TX_frequency/1000000;
      if (f1 > 9)
      {
        myGLCD.drawBitmap(1, 16, bit_map_1, 4, 16); 
        myGLCD.printNumI(f1-10, 4, 16, 1, '0');
      }
      else
        myGLCD.printNumI(f1, 4, 16, 1); 
      f2 = TX_frequency/1000 - f1*1000;
      
      myGLCD.printNumI(f2, 20, 16, 3, '0');
      myGLCD.printNumI((TX_frequency - f1*1000000 - f2*1000)/10, 60, 16, 2, '0');
      myGLCD.drawBitmap(17, 24, bit_map_dot, 2, 8);
      myGLCD.drawBitmap(57, 24, bit_map_dot, 2, 8);

      myGLCD.setFont(SmallFont);
      if ( z == 1 ) myGLCD.print("     TX", RIGHT, 0);
    }
    myGLCD.setFont(SmallFont);
    myGLCD.print(bwtext[Selected_BW],0,40);
    myGLCD.print(steptext[Selected_Step],10,40);

    if ( !z ) {
      MeterReadValue = analogRead(SmeterReadPin);
    }
    else
    {
      MeterReadValue = 0; 
    }
    MeterReadValue = map(MeterReadValue, 0, 170, 0, 11);
    for (int i=1; i <= MeterReadValue; i++) {
      if ( i == 5 || i == 9 )
      {
        myGLCD.printNumI(i, (i-1)*8, 8);
      }  
      else
      {
        myGLCD.print("=", (i-1)*8, 8); 
      }
    }
    
    if(ST_key == 0) {   //Paddle speed)
      myGLCD.printNumI(CWSpeed,32,40,2);
    }
    else
    {
      myGLCD.print("ST",32,40);
    }       
    
    myGLCD.print(CatStatus,50,40);
    
    BatteryReadValue = analogRead(BatteryReadPin)* BatteryVconvert;
    myGLCD.printNumF(float(BatteryReadValue), 1, RIGHT, 40);
    
    if ( z == 3 )                    myGLCD.print(txt75, RIGHT, 0);
    if ( Selected_Other == 1 && !z ) myGLCD.print(txt76, RIGHT, 0);
    if ( tune )                      myGLCD.print(txt73, RIGHT, 0);
    if ( Selected_Other == 2 && !z ) myGLCD.print(txt74, RIGHT, 0);
}

//Terminal output
void Terminal_Refresh(int z)  
{
  if ( terminal && !tune) {
    Serial.print("\e[1;1H\e[2J");                      // Cursor to 1,1 left top corner

    // 1st Line frequency and RIT or Message
    RX_frequency = frequency_tune + IF;
    TX_frequency = frequency + IF;
    if ( !z ) {	                                       // RX status
      Serial.print(RX_frequency * 0.001);
      Serial.print("   ");
      //RIT or MESSAGE
      if ( Selected_Other == 0 ) {
        Serial.print(RitFreqOffset);
      }
      if ( Selected_Other == 1 ) {
        Serial.print(txt76);
      }    
      if ( Selected_Other == 2 || tune) {
        Serial.print(txt74);
      }  
      Serial.println();
    } 
    else
    {                                                  // TX status 
      Serial.print(TX_frequency * 0.001);
      Serial.print("   ");
      if ( z == 1 ) Serial.print("TX");
      if ( z == 3 ) Serial.print(txt75);
      if ( z == 2 ) Serial.print(txt73);
      Serial.println();
    }
    // 2nd line, BW, STEP, SPEED,
    Serial.print(bwtext[Selected_BW]);
    Serial.print(" ");
    Serial.print(steptext[Selected_Step]);
    Serial.print(" ");

    if(ST_key == 0) {  
       Serial.print(CWSpeed);
       Serial.print(" ");

    }
    else
    {
       Serial.print("ST ");
    }

    // S Meter 
    if ( !z ) {
      MeterReadValue = analogRead(SmeterReadPin);
    }
    else
    {
      MeterReadValue = 0;
    }
    MeterReadValue = map(MeterReadValue, 0, 170, 0, 9);
    Serial.print(MeterReadValue);
    
    // DC Volts In
    BatteryReadValue = analogRead(BatteryReadPin)* BatteryVconvert;
    Serial.print(" ");
    Serial.print(BatteryReadValue);
  }
}

// -------------------- Ten*Tec led routines ---------------------
void Step_Flash()
{
    stop_led_on();
    for (int i=0; i <= 25e3; i++); // short delay 
    stop_led_off();   
}

void stop_led_on()
{
    digitalWrite(Band_End_Flash_led, HIGH);
}

void stop_led_off()
{
    digitalWrite(Band_End_Flash_led, LOW);
}

// -------------  Menu routines --------------------------------------
void Multi_Function() // The right most pushbutton for BW, Step, Other
{
    Step_Multi_Function_Button = digitalRead(Multi_Function_Button);
    if (Step_Multi_Function_Button == HIGH) 
    {  
       // Debounce start
       unsigned long time;
       unsigned long start_time;
       #ifdef FEATURE_BANDSWITCH
         unsigned long long_time;
         long_time = millis();
       #endif
      
       time = millis();
       while( digitalRead(Multi_Function_Button) == HIGH ){ 
         
         #ifdef FEATURE_BANDSWITCH
           // function button is pressed longer then  0.5 seconds
           if ( (millis() - long_time) > 500 && (millis() - long_time) < 510 ) { 
             // change band and load default frequency
             if ( bsm == 1 )
             {
               bsm = 0;
               Band_Set_40_20M();
             }
             else
             {
               bsm = 1;
               Band_Set_40_20M();
             }   
        
             // wait for button release
             while( digitalRead(Multi_Function_Button) == HIGH ){ 
             } 
             myGLCD.clrScr();   // clears the screen and buffer
             
             return;        
           } 
         #endif
         
         start_time = time;
         while( (time - start_time) < 7) {
           time = millis();
         }
       } // Debounce end

        Step_Multi_Function_Button1 = Step_Multi_Function_Button1++;
        if (Step_Multi_Function_Button1 > 2 ) 
        { 
            Step_Multi_Function_Button1 = 0; 
        }
    }
    Step_Function();
}

void Step_Function()
{
    switch ( Step_Multi_Function_Button1 )
    {
        case 0:
            MF_G();
            Step_Select_Button1 = Selected_BW;  
            Step_Select(); 
            Selection();
            break;   

        case 1:
            MF_Y();
            Step_Select_Button1 = Selected_Step; 
            Step_Select(); 
            Selection();
            break;   

        case 2: 
            MF_R();
            Step_Select_Button1 = Selected_Other; 
            Step_Select(); 
            Selection();
            break;    
    }
}

void  Selection()
{
    Step_Select_Button = digitalRead(Select_Button);
    if (Step_Select_Button == HIGH) 
    {   
       // Debounce start
       unsigned long time;
       unsigned long start_time;
       unsigned long long_time;
       long_time = millis();
       
       time = millis();
       while( digitalRead(Select_Button) == HIGH ){ 
         
         // function button is pressed longer then 0.5 seconds
         if ( (millis() - long_time) > 500 && (millis() - long_time) < 510 && Selected_Other == Other_1_user ) { 
           // announce frequency
           TX_frequency = (frequency + IF)/100;
           char buffer[8];
           ltoa(TX_frequency, buffer, 10);
           announce(buffer);
           // wait for button release
           while( digitalRead(Select_Button) == HIGH ){ 
           }   
           return;        
         } 
         start_time = time;
         while( (time - start_time) < 7) {
           time = millis();
         }
       } // Debounce end
        Step_Select_Button1 = Step_Select_Button1++;
        if (Step_Select_Button1 > 2 ) 
        { 
            Step_Select_Button1 = 0; 
        }
    }
    Step_Select(); 
}

void Step_Select()
{
    switch ( Step_Select_Button1 )
    {
        case 0: //   Select_Green   could place the S_G() routine here!
            S_G();
            break;

        case 1: //   Select_Yellow  could place the S_Y() routine here!
            S_Y();
            break; 

        case 2: //   Select_Red    could place the S_R() routine here!
            S_R();
            break;     
    }
}

void MF_G()    //  Multi-function Green 
{
    digitalWrite(Multi_function_Green, HIGH);    
    digitalWrite(Multi_function_Yellow, LOW);  
    digitalWrite(Multi_function_Red, LOW);  
}

void MF_Y()   //  Multi-function Yellow
{
    digitalWrite(Multi_function_Green, LOW);    
    digitalWrite(Multi_function_Yellow, HIGH);  
    digitalWrite(Multi_function_Red, LOW);  
}

void MF_R()   //  Multi-function Red
{
    digitalWrite(Multi_function_Green, LOW);
    digitalWrite(Multi_function_Yellow, LOW);  
    digitalWrite(Multi_function_Red, HIGH);
}

void S_G()  // Select Green 
{
    digitalWrite(Select_Green, HIGH); 
    digitalWrite(Select_Yellow, LOW);  
    digitalWrite(Select_Red, LOW); 
    if (Step_Multi_Function_Button1 == 0)  
        Band_Width_W(); 
    else if (Step_Multi_Function_Button1 == 1)  
        Step_Size_100(); 
    else if (Step_Multi_Function_Button1 == 2)  
        Other_1(); 
}

void S_Y()  // Select Yellow
{
    digitalWrite(Select_Green, LOW); 
    digitalWrite(Select_Yellow, HIGH);   
    digitalWrite(Select_Red, LOW); 
    if (Step_Multi_Function_Button1 == 0) 
    {
        Band_Width_M();
    } 
    else if (Step_Multi_Function_Button1 == 1) 
    {
        Step_Size_1k(); 
    }
    else if (Step_Multi_Function_Button1 == 2) 
    {
        Other_2();
    }
}

void S_R()  // Select Red
{
    digitalWrite(Select_Green, LOW);  
    digitalWrite(Select_Yellow, LOW);   
    digitalWrite(Select_Red, HIGH);    
    if (Step_Multi_Function_Button1 == 0) 
    {
        Band_Width_N();
    } 
    else if (Step_Multi_Function_Button1 == 1) 
    {
        Step_Size_10k(); 
    }
    else if (Step_Multi_Function_Button1 == 2) 
    {
        Other_3(); 
    }
}

void Band_Width_W()
{
    digitalWrite( Medium_A8, LOW);   // Hardware control of I.F. filter shape
    digitalWrite( Narrow_A9, LOW);   // Hardware control of I.F. filter shape
    Selected_BW = Wide_BW; 
}

void Band_Width_M()
{
    digitalWrite( Medium_A8, HIGH);  // Hardware control of I.F. filter shape
    digitalWrite( Narrow_A9, LOW);   // Hardware control of I.F. filter shape
    Selected_BW = Medium_BW;  
}

void Band_Width_N()
{
    digitalWrite( Medium_A8, LOW);   // Hardware control of I.F. filter shape
    digitalWrite( Narrow_A9, HIGH);  // Hardware control of I.F. filter shape
    Selected_BW = Narrow_BW; 
}

void Step_Size_100()                 // Encoder Step Size 
{
    frequency_step = 25;            //  Can change this whatever step size one wants
    Selected_Step = Step_100_Hz; 
}

void Step_Size_1k()                 // Encoder Step Size 
{
    frequency_step = 250;           //  Can change this whatever step size one wants
    Selected_Step = Step_1000_hz; 
}

void Step_Size_10k()                // Encoder Step Size 
{
    frequency_step = 2.5e3;          //  Can change this whatever step size one wants
    Selected_Step = Step_10000_hz; 
}

void Other_1()                      // User Defined Control Software 
{
  if ( tune == 1 ) tune= 2;         // Switch off Tune mode TX 
  Selected_Other = Other_1_user; 
}

void Other_2()                      //  Send CQ message 
{
  if ( Selected_Other != Other_2_user ) cqStartTime = millis() - ((CQ_DELAY-1)*1000);
  Selected_Other = Other_2_user; 
}

void Other_3()                      //  Set TX in TUNE 
{
  if ( Selected_Other != Other_3_user ) tuneStartTime = millis();  
  Selected_Other = Other_3_user;
}

uint32_t TimerOverFlow(uint32_t currentTime)
{
    return (currentTime + CORE_TICK_RATE*(1));//the Core Tick Rate is 1ms
}

//-----------------------------------------------------------------------------


// ****************  Dont bother the code below  ******************************
// \/  \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ \/ \/
//-----------------------------------------------------------------------------
void program_freq0(long frequency)
{
    //AD9834_reset_high();  
    int flow,fhigh;
    fcalc = frequency*(268.435456e6 / Reference );    // 2^28 =
    flow = fcalc&0x3fff;              //  49.99975mhz  
    fhigh = (fcalc>>14)&0x3fff;
    digitalWrite(FSYNC_BIT, LOW);  //
    clock_data_to_ad9834(flow|AD9834_FREQ0_REGISTER_SELECT_BIT);
    clock_data_to_ad9834(fhigh|AD9834_FREQ0_REGISTER_SELECT_BIT);
    digitalWrite(FSYNC_BIT, HIGH);
    //AD9834_reset_low();
}    // end   program_freq0

//------------------------------------------------------------------------------
void program_freq1(long frequency)
{
    //AD9834_reset_high(); 
    int flow,fhigh;
    fcalc = frequency*(268.435456e6 / Reference );    // 2^28 =
    flow = fcalc&0x3fff;              //  use for 49.99975mhz   
    fhigh = (fcalc>>14)&0x3fff;
    digitalWrite(FSYNC_BIT, LOW);  
    clock_data_to_ad9834(flow|AD9834_FREQ1_REGISTER_SELECT_BIT);
    clock_data_to_ad9834(fhigh|AD9834_FREQ1_REGISTER_SELECT_BIT);
    digitalWrite(FSYNC_BIT, HIGH);  
    //AD9834_reset_low();
}  

//------------------------------------------------------------------------------
void clock_data_to_ad9834(unsigned int data_word)
{
    char bcount;
    unsigned int iData;
    iData=data_word;
    digitalWrite(SCLK_BIT, HIGH);  //portb.SCLK_BIT = 1;  
    // make sure clock high - only chnage data when high
    for(bcount=0;bcount<16;bcount++)
    {
        if((iData & 0x8000)) digitalWrite(SDATA_BIT, HIGH);  //portb.SDATA_BIT = 1; 
        // test and set data bits
        else  digitalWrite(SDATA_BIT, LOW);  
        digitalWrite(SCLK_BIT, LOW);  
        digitalWrite(SCLK_BIT, HIGH);     
        // set clock high - only change data when high
        iData = iData<<1; // shift the word 1 bit to the left
    }  // end for
}  // end  clock_data_to_ad9834

//-----------------------------------------------------------------------------
void AD9834_init()      // set up registers
{
    AD9834_reset_high(); 
    digitalWrite(FSYNC_BIT, LOW);
    clock_data_to_ad9834(0x2300);  // Reset goes high to 0 the registers and enable the output to mid scale.
    clock_data_to_ad9834((FREQ0_INIT_VALUE&0x3fff)|AD9834_FREQ0_REGISTER_SELECT_BIT);
    clock_data_to_ad9834(((FREQ0_INIT_VALUE>>14)&0x3fff)|AD9834_FREQ0_REGISTER_SELECT_BIT);
    clock_data_to_ad9834(0x2200); // reset goes low to enable the output.
    AD9834_reset_low();
    digitalWrite(FSYNC_BIT, HIGH);  
}  //  end   init_AD9834()

//----------------------------------------------------------------------------   
void AD9834_reset()
{
    digitalWrite(RESET_BIT, HIGH);  // hardware connection
    for (int i=0; i <= 2048; i++);  // small delay

    digitalWrite(RESET_BIT, LOW);   // hardware connection
}

//-----------------------------------------------------------------------------
void AD9834_reset_low()
{
    digitalWrite(RESET_BIT, LOW);
}

//-----------------------------------------------------------------------------     
void AD9834_reset_high()
{  
    digitalWrite(RESET_BIT, HIGH);
}
//^^^^^^^^^^^^^^^^^^^^^^^^^  DON'T BOTHER CODE ABOVE  ^^^^^^^^^^^^^^^^^^^^^^^^^ 
//=============================================================================

