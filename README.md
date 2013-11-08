Hello Ten-Tec Rebel model 506 users.

The code presented here is build together with Paul- KD8FJO and James - K4JK and work is ongoing as we speak. The code uses as base the released Rebel_Base verion from Ten-Tec and we added:

1. (KD8FJO) Added Optional feature selection. 
2. (K4JK) Added simple IAMBIC keyer. Code adapted from openqrp.org. w/ analog speed control
3. (PA3ANG) Added Beacon. Can be activated by selecting U3 in USER menu. 
4. (PA3ANG) Changed LCD_4BIT layout and info
  - 1st line, Header with software version info, mode (K=Keyer,S=Straight Key) and band
  - 2nd line, RX frequecy plus RIT deviation during RX and TX frequency during TX 
  - 3rd line, BW, STEP, S or P bar meter, CW SPEED
  - 4th line, reserved for CW decoder
5. (PA3ANG) Added entering frequency using Serial Port
6. (PA3ANG) Added CAT Control
7. (PA3ANG) Added Band Switching w/ additional Hardware  FUNCTION > 2 seconds
8. (PA3ANG) Added Freq Announce SELECT > 2 seconds
9. (KD8FJO) NOKIA 5110 display and tested all other I2C display modules

73 Johan, PA3ANG   at amsat.org

More info Yahoo group @ http://groups.yahoo.com/neo/groups/TenTec506Rebel

Note: You need to load the libraries into you MPIDE /hardware/pic32/libraries/  directory and restart MPIDE. The libraries can be found here and on github/pstyle/tentec506.
