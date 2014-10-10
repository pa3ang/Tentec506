
/*
<RebelAllianceMod for the TenTec Rebel 506 QRP Tranciever See PROJECT REBEL QRP below>
** This is a modified version of the code released by TenTec and the Rebel Alliance Mod V1.1. **
** FUNCTION AVAILABLE ARE: BANDSWITCH, IAMBIC KEYER (A7 SPEED), BEACON/CQ + ANNOUNCE FREQ **
** NOKIA5110 DISPLAY, DISPLAY DATA VIA USB  **
*/

  
// various defines
#define SDATA_BIT                           10          //  keep!
#define SCLK_BIT                            8           //  keep!
#define FSYNC_BIT                           9           //  keep!
#define RESET_BIT                           11          //  keep!
#define FREQ_REGISTER_BIT                   12          //  keep!
#define AD9834_FREQ0_REGISTER_SELECT_BIT    0x4000      //  keep!
#define AD9834_FREQ1_REGISTER_SELECT_BIT    0x8000      //  keep!
#define FREQ0_INIT_VALUE                    0x01320000  //  keep?

#define led                                 13          // Ten*Ten led
#define Side_Tone                           3           // maybe to be changed to a logic control
                                                        // for a separate side tone gen
#define TX_Dah                              33          //  keep!
#define TX_Dit                              32          //  keep!
#define TX_OUT                              38          //  keep!

#define Band_End_Flash_led                  24          // also this led will flash every 100/1khz/10khz is tuned
#define Band_Select                         41          // if shorting block on only one pin 20m(1) on both pins 40m(0)
#define Multi_Function_Button               2           //
#define Multi_function_Green                34          // For now assigned to BW (Band width)
#define Multi_function_Yellow               35          // For now assigned to STEP size
#define Multi_function_Red                  36          // For now assigned to USER

#define Select_Button                       5           // 
#define Select_Green                        37          // Wide/100/USER1
#define Select_Yellow                       39          // Medium/1K/USER2
#define Select_Red                          40          // Narrow/10K/USER3

#define Medium_A8                           22          // Hardware control of I.F. filter Bandwidth
#define Narrow_A9                           23          // Hardware control of I.F. filter Bandwidth

#define Wide_BW                             0           // About 2.1 KHZ
#define Medium_BW                           1           // About 1.7 KHZ
#define Narrow_BW                           2           // About 1 KHZ

#define Step_100_Hz                         0
#define Step_1000_hz                        1
#define Step_10000_hz                       2

#define  Other_1_user                       0           // 
#define  Other_2_user                       1           //
#define  Other_3_user                       2           //

//-------------------------------  SET OPTONAL FEATURES HERE  -------------------------------------------------------------
//#define FEATURE_DISPLAY                // NOKIA5110 Dipslay. The only supported display becuse it's cheap, fast, and only a few wires
#define FEATURE_TERMINAL               // Send display info through the USB port

#define FEATURE_KEYER                  // Keyer based on code from OpenQRP.org with trimpot A7 as speed control

#define FEATURE_BEACON_CQ              // Use USER Menu 3 or U2 to run message.  Make sure to change the Beacon text below! 
#define FEATURE_FREQANNOUNCE           // Announce Frequency by keying side tone (not TX). Press SELECT > 2 seconds  

#define FEATURE_BANDSWITCH             // Software based Band Switching.  Press FUNCTION > 2 seconds  NEEDS ADDITIONAL HARDWARE
//--------------------------------------------------------------------------------------------------------------------------

// various defines continue
const int RitReadPin        = A0;      // pin that the sensor is attached to used for a rit routine later.
int RitReadValue            = 0;
int RitFreqOffset           = 0;

const int SmeterReadPin     = A1;      // To give a realitive signal strength based on AGC voltage.
const int PowerOutReadPin   = A3;      // Reads RF out voltage at Antenna.
int MeterReadValue         = 0;

const int BatteryReadPin    = A2;      // Reads 1/5 th or 0.20 of supply voltage.
float BatteryReadValue      = 0;
float BatteryVconvert       = 0.01707; //callibrated on 13.8v ps

const int CodeReadPin       = A6;      // Can be used to decode CW. 
int CodeReadValue           = 0;

const int CWSpeedReadPin    = A7;      // To adjust CW speed for user written keyer.
int CWSpeedReadValue        = 0;            
unsigned long ditTime;                 // No. milliseconds per dit
int ST_key;

// FEATURES
#ifdef FEATURE_BEACON_CQ
  #define FEATURE_BEACON_OR_FREQANNOUNCE
  // Simple Arduino CW Beacon Keyer
  // Written by Mark VandeWettering K6HX
  #define     BEACON          ("VVV DE PA3ANG BEACON JO32AM")              // Beacon text 
  #define     CQ              ("CQCQCQ DE PA3ANG PA3ANG PA3ANG PSE K")     // CQ text 
#endif

#ifdef FEATURE_FREQANNOUNCE
  #define FEATURE_BEACON_OR_FREQANNOUNCE
#endif

#ifdef FEATURE_BEACON_OR_FREQANNOUNCE
  #define     CW_SPEED        20                                 // Beacon Speed    is fixed !!
  #define     BEACON_DELAY    10                                 // in seconds
  #define     N_MORSE  (sizeof(morsetab)/sizeof(morsetab[0]))    // Morse Table
  #define     DOTLEN   (1200/CW_SPEED)                           // No. milliseconds per dit
  #define     DASHLEN  (3*(1200/CW_SPEED))                       // CW weight  3.5 / 1   !! was 3.5*
  // Beacon and Announce Variables
  unsigned long  beaconStartTime    = 0;
  unsigned long  beaconElapsedTime  = 0;
  // Morse table
  struct t_mtab { char c, pat; } ;
  struct t_mtab morsetab[] = {
  	{'.', 106}, {',', 115},	{'?', 76}, {'/', 41}, {'A', 6},  {'B', 17}, {'C', 21}, {'D', 9}, 
        {'E', 2},   {'F', 20},  {'G', 11}, {'H', 16}, {'I', 4},  {'J', 30}, {'K', 13}, {'L', 18}, 
        {'M', 7},   {'N', 5},   {'O', 15}, {'P', 22}, {'Q', 27}, {'R', 10}, {'S', 8},  {'T', 3}, 
        {'U', 12},  {'V', 24},  {'W', 14}, {'X', 25}, {'Y', 29}, {'Z', 19}, {'1', 62}, {'2', 60}, 
        {'3', 56},  {'4', 48},  {'5', 32}, {'6', 33}, {'7', 35}, {'8', 39}, {'9', 47}, {'0', 63}
  };
#endif  // FEATURE_BEACON_OR_FREQANNOUNCE

#ifdef FEATURE_KEYER
  //  keyerControl bit definitions
  #define     DIT_L      0x01     // Dit latch
  #define     DAH_L      0x02     // Dah latch
  #define     DIT_PROC   0x04     // Dit is being processed
  #define     PDLSWAP    0x08     // 0 for normal, 1 for swap
  #define     IAMBICB    0x10     // 0 for Iambic A, 1 for Iambic B
  //Keyer Variables
  unsigned char       keyerControl;
  unsigned char       keyerState;
  enum KSTYPE {IDLE, CHK_DIT, CHK_DAH, KEYED_PREP, KEYED, INTER_ELEMENT };
#endif // FEATURE_KEYER

  #define bw 3
  String bwtext[bw] = { "W", "M", "N" };
  #define stp 3
  String steptext[stp] = {"100", "1K ", "10K"};
  // define Display text constants		
  const char txt0[22]         = "V2.0";
  const char txt2[22]         = "Rebel";
  const char txt73[7]         = "BEACON";
  const char txt74[7]         = "BDELAY";
  const char txt75[7]         = "CQCQCQ";
  const char txt76[7]         = "CQDELY";
  
#ifdef FEATURE_DISPLAY
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
#endif // FEATURE_DISPLAY

int y;

int terminal_enabled = 1;
String CatStatus;
unsigned long  catStartTime    = 0;
unsigned long  catElapsedTime  = 0;
// bsm=0 is 40 meter, bsm=1 is 20 meter (original Rebel configuration)
int Band_bsm0_Low              = 700000;
int Band_bsm0_High             = 720000;
int Band_bsm1_Low              = 1400000;
int Band_bsm1_High             = 1435000;

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
int n                           = LOW;

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

void Step_Size_100();           //   100 hz step
void Step_Size_1k();            //   1 kilo-hz step
void Step_Size_10k();           //   10 kilo-hz step

void Other_1();                 //   user 1
void Other_2();                 //   user 2
void Other_3();                 //   user 3 

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
    pinMode (Band_Select,           INPUT);     // Band select via Jumpers.
  #endif

  #ifdef FEATURE_BANDSWITCH
    pinMode (Band_Select,           OUTPUT);    // Used to control relays connected to fileter lines.
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

  #ifdef FEATURE_DISPLAY
    myGLCD.InitLCD();
    myGLCD.drawBitmap(0, 4, tentec, 84, 44);
    delay(5000);
    myGLCD.clrScr();
  #endif 
  
  #ifdef FEATURE_TERMINAL
    Serial.begin(115200);                       //Enable serial to port display data
  #endif
 
  #ifdef FEATURE_KEYER
    keyerState = IDLE;
    keyerControl = IAMBICB;      
    checkWPM();                                // Set default CW Speed 
    //See if user wants to use a straight key
    if ((digitalRead(TX_Dah) == LOW) || (digitalRead(TX_Dit) == LOW)) {    //Is a lever pressed?
      ST_key = 1;                              //If so, enter straight key mode   
    }
  #endif

  #ifndef FEATURE_KEYER
    ST_key = 1;
  #endif
}   //    end of setup


// Default settings 
void Default_Settings()
{
  digitalWrite(Multi_function_Green,  LOW);    // Band_Width
                                               // place control here
  digitalWrite(Multi_function_Yellow, LOW);    //
                                               // place control here
  digitalWrite(Multi_function_Red,    HIGH);   //
                                               // place control here
  digitalWrite(Select_Green,          LOW);    //  
                                               // place control here 
  digitalWrite(Select_Yellow,         HIGH);   //
  Band_Width_M();                              // place control here
  digitalWrite(Select_Green,          LOW);    //
                                               // place control here
  digitalWrite(TX_OUT,                LOW);   

  digitalWrite(FREQ_REGISTER_BIT,     LOW);    //This is set to LOW so RX is not dead on power on        
                                                
  digitalWrite(Band_End_Flash_led,    LOW);

  digitalWrite(Side_Tone,             LOW);    
}

//======================= Main Loop =================================
void loop()      
{
  digitalWrite(FSYNC_BIT,             HIGH);   // 
  digitalWrite(SCLK_BIT,              HIGH);   //

  RIT_Read();
  Multi_Function(); 
  Encoder();

  frequency_tune  = frequency + RitFreqOffset;
  UpdateFreq(frequency_tune);
  TX_routine();

 #ifdef FEATURE_BEACON_CQ
    if ( Selected_Other == 1 ) 
    {
      beaconElapsedTime = millis() - beaconStartTime; 
      if( (BEACON_DELAY *1000) <= beaconElapsedTime )
      {
        #ifdef FEATURE_DISPLAY
          NOKIA5110_Refresh(3);
        #endif
        #ifdef FEATURE_TERMINAL
          Terminal_Refresh(3); 
        #endif

        sendmsg(CQ);
        beaconStartTime = millis();  //Reset the Timer for the beacon loop
      }
    }
   if ( Selected_Other == 2 ) 
    {
      beaconElapsedTime = millis() - beaconStartTime; 
      if( (BEACON_DELAY *1000) <= beaconElapsedTime )
      {
        #ifdef FEATURE_DISPLAY
          NOKIA5110_Refresh(2);
        #endif
        #ifdef FEATURE_TERMINAL
          Terminal_Refresh(2); 
        #endif

        sendmsg(BEACON);
        beaconStartTime = millis();  //Reset the Timer for the beacon loop
      }
    }
  #endif  //FEATURE_BEACON_CQ
    
  loopCount++;
  loopElapsedTime    = millis() - loopStartTime;    // comment this out to remove the one second tick
  // has 500 milliseconds elasped?
  if( 500 <= loopElapsedTime )
    {
      #ifdef FEATURE_KEYER
        checkWPM();
      #endif
   
      #ifdef FEATURE_DISPLAY
        NOKIA5110_Refresh(0); 
      #endif
      
      #ifdef FEATURE_TERMINAL
        Terminal_Refresh(0); 
      #endif
      
      y=1;
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
    for (int t=0; t < (4-(bsm*2));) {
      Step_Flash(); 
      for (int i=0; i <= 200e3; i++); 
      t++;
    }
  }
#endif  //FEATURE_BANDSWITCH

//--------------------------- Encoder Routine ----------------------------  
void Encoder()
{  
    n = digitalRead(encoder0PinA);
    if ((encoder0PinALast == LOW) && (n == HIGH)) 
    {
        if (digitalRead(encoder0PinB) == LOW) 
        {
            Frequency_down();    //encoder0Pos--;
        } else 
        {
            Frequency_up();       //encoder0Pos++;
        }
    } 
    encoder0PinALast = n;
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
void TX_routine()
{
  if (ST_key == 1) {   // is ST_Key is set to YES? Then use Straight key mode
                       // Will detect straight key at startup.
                       // Will also do this routine if FEATURE_KEYER not selected
    TX_key = digitalRead(TX_Dit);
    if ( TX_key == LOW)         // was high   
    {
        do
        {
            digitalWrite(FREQ_REGISTER_BIT, HIGH);
            digitalWrite(TX_OUT, HIGH);
            digitalWrite(Side_Tone, HIGH);
            if (y == 1)                      // flag indicating 1st switch from RX to TX
            {
              for (int i=0; i <= 10e3; i++); // delay for power meter to establish
              #ifdef FEATURE_DISPLAY
                NOKIA5110_Refresh(y);
              #endif
              #ifdef FEATURE_TERMINAL
                Terminal_Refresh(1);
              #endif
              y=0;
            }
            TX_key = digitalRead(TX_Dit);
        } while (TX_key == LOW);         // was high 

        digitalWrite(TX_OUT, LOW);      // turn off TX
        for (int i=0; i <= 10e3; i++);  // delay for maybe some decay on key release
        digitalWrite(FREQ_REGISTER_BIT, LOW);
        digitalWrite(Side_Tone, LOW);
        loopStartTime = millis();       //Reset the Timer for this loop
    }
  } 
  else
  {                     //If ST_key is not 1, then use IAMBIC
    #ifdef FEATURE_KEYER
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
        digitalWrite(FREQ_REGISTER_BIT, HIGH);
        digitalWrite(TX_OUT, HIGH);           // key the line
        digitalWrite(Side_Tone, HIGH);        // Tone
        ktimer += millis();                   // set ktimer to interval end time
        keyerControl &= ~(DIT_L + DAH_L);     // clear both paddle latch bits
        keyerState = KEYED;                   // next state
        break;
        
    case KEYED:
        // Wait for timer to expire
        if (y == 1)                      // flag indicating 1st switch from RX to TX
        {
          for (int i=0; i <= 10e3; i++); // delay for power meter to establish
          #ifdef FEATURE_DISPLAY
            NOKIA5110_Refresh(y);
          #endif
          #ifdef FEATURE_TERMINAL
            Terminal_Refresh(y);
          #endif
          y=0;
        }
        if (millis() > ktimer) {              // are we at end of key down ?
            digitalWrite(TX_OUT, LOW);        // turn the key off
            for (int i=0; i <= 10e3; i++);    // delay for maybe some decay on key release
            digitalWrite(FREQ_REGISTER_BIT, LOW);
            digitalWrite(Side_Tone, LOW);
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
                loopStartTime = millis();     //Reset the Timer for this loop
            }
        }
        break;
  }
  #endif
 }
 
}

//    Latch dit and/or dah press
//    Called by keyer routine
#ifdef FEATURE_KEYER
  void update_PaddleLatch()
  {
    if (digitalRead(TX_Dit) == LOW) {
        keyerControl |= DIT_L;
    }
    if (digitalRead(TX_Dah) == LOW) {
        keyerControl |= DAH_L;
    }
  }
#endif

// Calculate new time constants based on wpm value
void loadWPM(int wpm)
{
    ditTime = 1200/(wpm+3);              // correction factor = 3
}
// Checks the Keyer speed Pot and updates value 
void checkWPM() 
{
   CWSpeedReadValue = analogRead(CWSpeedReadPin);
   CWSpeedReadValue = map(CWSpeedReadValue, 0, 1024, 5, 45);
   loadWPM(CWSpeedReadValue);
}

// Beacon and CQ Routines
#ifdef FEATURE_BEACON_CQ
  // CW generation routines for Beacon and Memory 
  void key(int LENGTH) {
    digitalWrite(FREQ_REGISTER_BIT, HIGH);
    digitalWrite(TX_OUT, HIGH);          // key the line
    digitalWrite(Side_Tone, HIGH);       // Tone
    delay(LENGTH);
    digitalWrite(TX_OUT, LOW);           // turn the key off
    //for (int i=0; i <= 10e3; i++);       // delay for maybe some decay on key release
    digitalWrite(FREQ_REGISTER_BIT, LOW);
    digitalWrite(Side_Tone, LOW);
    delay(DOTLEN) ;
  }

  void send(char c) {
    int i ;
    if (c == ' ') {
      delay(7*DOTLEN) ;
      return ;
    }
    if (c == '+') {
      delay(4*DOTLEN) ; 
      key(DOTLEN);
      key(DASHLEN);
      key(DOTLEN);
      key(DASHLEN);
      key(DOTLEN);
      delay(4*DOTLEN) ; 
      return ;
    }    
    
    for (i=0; i<N_MORSE; i++) {
      if (morsetab[i].c == c) {
        unsigned char p = morsetab[i].pat ;
        while (p != 1) {
          if (p & 1)
            key(DASHLEN) ;
          else
            key(DOTLEN) ;
          p = p / 2 ;
          }
        delay(2*DOTLEN) ;
        return ;
        }
    }
  }

  void sendmsg(char *str) {
    while (*str) {
      if (digitalRead(TX_Dit) == LOW || digitalRead(TX_Dah) == LOW ) 
    {
    // stop automatic transmission Beacon and CQ
    Selected_Other = Other_1_user;
    Step_Multi_Function_Button1 = 0;
    Step_Function();
    return;
    }
      send(*str++) ;
    }  
  }
#endif //FEATURE_BEACON_CQ

// More then 2 second SELECT is Freq Announce
#ifdef FEATURE_FREQANNOUNCE
  void announce(char *str) {
    while (*str) 
      key_announce(*str++); 
  }

  void beep(int LENGTH) {
    digitalWrite(Side_Tone, HIGH);
    delay(LENGTH);
    digitalWrite(Side_Tone, LOW);
    delay(DOTLEN) ;
  }

  void key_announce(char c) {
    for (int i=0; i<N_MORSE; i++) {
      if (morsetab[i].c == c) {
        unsigned char p = morsetab[i].pat ;
        while (p != 1) {
          if (p & 1)
            beep(DASHLEN) ;
          else
            beep(DOTLEN) ;
          p = p / 2 ;
        }
        delay(2*DOTLEN) ;
        return ;
        }
    }
  }
#endif  //FEATURE_FREQANNOUNCE

// RIT routine  
void RIT_Read()
{
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
void  Band_40_Limit_High()
    {
         if ( frequency < 16.3e6 )
    { 
         stop_led_off();
    } 
    
    else if ( frequency >= 16.3e6 )
    { 
       frequency = 16.3e6;
         stop_led_on();    
    }
}
 
void  Band_40_Limit_Low()
    {
        if ( frequency <= 16.0e6 )  
    { 
        frequency = 16.0e6;
        stop_led_on();
    } 
    
    else if ( frequency > 16.0e6 )
    { 
       stop_led_off();
    } 
}
   
void  Band_20_Limit_High()
    {
         if ( frequency < 5.35e6 )
    { 
         stop_led_off();
    } 
    
    else if ( frequency >= 5.35e6 )
    { 
       frequency = 5.35e6;
         stop_led_on();    
    }
}

void  Band_20_Limit_Low()
    {
        if ( frequency <= 5.0e6 )  
    { 
        frequency = 5.0e6;
        stop_led_on();
    } 
    
    else if ( frequency > 5.0e6 )
    { 
        stop_led_off();
    } 
 }

// Frequency set routines
void Default_frequency()
{
    frequency = frequency_default;
    UpdateFreq(frequency);

}

//------------------------Display Stuff below-----------------------------------

#ifdef FEATURE_DISPLAY
  void NOKIA5110_Refresh(int z)  
  {
    myGLCD.print(txt2,0,0);
    
    RX_frequency = frequency_tune + IF;
    TX_frequency = frequency + IF;

    myGLCD.clrRow(1);
    myGLCD.setFont(MediumNumbers);
    if ( !z ) {	
      myGLCD.printNumF(float(RX_frequency * 0.001), 1, CENTER, 16);

      myGLCD.setFont(SmallFont);
      myGLCD.clrRow(0, 42);
      if ( RitFreqOffset != 0) {
        myGLCD.printNumI(RitFreqOffset, RIGHT, 0);
      }
    }
    else
    {
      myGLCD.printNumF(float(TX_frequency * 0.001), 1, CENTER, 16);
      myGLCD.setFont(SmallFont);
      myGLCD.print("     TX", RIGHT, 0);
    }
    myGLCD.setFont(SmallFont);
    myGLCD.print(bwtext[Selected_BW],0,40);
    myGLCD.print(steptext[Selected_Step],10,40);

    if ( !z ) {
      MeterReadValue = analogRead(SmeterReadPin);
    }
    else
    {
      MeterReadValue = analogRead(PowerOutReadPin); 
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
      myGLCD.printNumI(CWSpeedReadValue,32,40);
    }
    else
    {
      myGLCD.print("ST",32,40);
    }       
    
    myGLCD.print(CatStatus,50,40);
    
    BatteryReadValue = analogRead(BatteryReadPin)* BatteryVconvert;
    myGLCD.printNumF(float(BatteryReadValue), 1, RIGHT, 40);
    

    #ifdef FEATURE_BEACON_CQ
      if ( z == 3 ) {
        myGLCD.print(txt75, RIGHT, 0);
      }    
      if ( Selected_Other == 1 && z != 3 ) {
        myGLCD.print(txt76, RIGHT, 0);
      }    
      if ( z == 2 ) {
        myGLCD.print(txt73, RIGHT, 0);
      }    
      if ( Selected_Other == 2 && z != 2 ) {
        myGLCD.print(txt74, RIGHT, 0);
      }    
    #endif
  }
#endif

//Terminal output
void Terminal_Refresh(int z)  
{
    Serial.print("\e[1;1H\e[2J");                      // Cursor to 1,1 left top corner

    // 1st Line frequency and RIT or Message
    RX_frequency = frequency_tune + IF;
    TX_frequency = frequency + IF;
    if ( !z ) {	
      Serial.print(RX_frequency * 0.001);
      Serial.print("   ");
      //RIT or MESSAGE
      #ifdef FEATURE_BEACON_CQ
        if ( Selected_Other == 0 ) {
          Serial.print(RitFreqOffset);
        }
        if ( Selected_Other == 1 ) {
          Serial.print(txt76);
        }    
        if ( Selected_Other == 2 ) {
          Serial.print(txt74);
        }  
      #endif
      Serial.println();
    } 
    else
    {
      Serial.print(TX_frequency * 0.001);
      Serial.print("   ");
      if ( z == 1 ) {
        Serial.print("TX");
      }
      #ifdef FEATURE_BEACON_CQ
        if ( z == 3 ) {
          Serial.print(txt75);
        }    
        if ( z == 2 ) {
          Serial.print(txt73);
        }    
      #endif
      Serial.println();
    }
    // 2nd line, BW, STEP, SPEED,
    Serial.print(bwtext[Selected_BW]);
    Serial.print(" ");
    Serial.print(steptext[Selected_Step]);
    Serial.print(" ");

    if(ST_key == 0) {  
       Serial.print(CWSpeedReadValue);
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
      MeterReadValue = analogRead(PowerOutReadPin);
    }
    MeterReadValue = map(MeterReadValue, 0, 170, 0, 9);
    Serial.print(MeterReadValue);
    
    // DC Volts In
    BatteryReadValue = analogRead(BatteryReadPin)* BatteryVconvert;
    Serial.print(" ");
    Serial.print(BatteryReadValue);
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
           // function button is pressed longer then 2 seconds
           if ( (millis() - long_time) > 2000 && (millis() - long_time) < 2010 ) { 
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
             #ifdef FEATURE_DISPLAY 
               myGLCD.clrScr();   // clears the screen and buffer
             #endif
             
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
       #ifdef FEATURE_FREQANNOUNCE
         unsigned long long_time;
         long_time = millis();
       #endif
       
       time = millis();
       while( digitalRead(Select_Button) == HIGH ){ 
         
         #ifdef FEATURE_FREQANNOUNCE
           // function button is pressed longer then 2 seconds
           if ( (millis() - long_time) > 2000 && (millis() - long_time) < 2010 ) { 
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
         #endif

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
    frequency_step = 100;            //  Can change this whatever step size one wants
    Selected_Step = Step_100_Hz; 
}

void Step_Size_1k()                 // Encoder Step Size 
{
    frequency_step = 1e3;           //  Can change this whatever step size one wants
    Selected_Step = Step_1000_hz; 
}

void Step_Size_10k()                // Encoder Step Size 
{
    frequency_step = 10e3;          //  Can change this whatever step size one wants
    Selected_Step = Step_10000_hz; 
}

void Other_1()                      //  User Defined Control Software 
{
    Selected_Other = Other_1_user; 
}

void Other_2()                      //  User Defined Control Software
{
    #ifdef FEATURE_BEACON_CQ
      // Start CQ after 2 seconds
      if ( Selected_Other != 1 ) 
      {
      beaconStartTime = millis() - ((BEACON_DELAY-2)*1000);  
      }
    #endif  // FEATURE_BEACON_CQ
    
    Selected_Other = Other_2_user; 
}

void Other_3()                      //  User Defined Control Software
{
    #ifdef FEATURE_BEACON_CQ
      // Start Beacon after 2 seconds
      if ( Selected_Other != 2 ) 
      {
      beaconStartTime = millis() - ((BEACON_DELAY-2)*1000);  
      }
    #endif  // FEATURE_BEACON_CQ
	
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

