// nxt{mote,gcc,squawk} basic debugger

#include "stdio.h"
#include "stdconst.h"
#include "modules.h"

#include "AT91SAM7S256.h"

#define   DEBUGCMD             0
#define   DEBUGDAT             1
#define   DEBUGDISP_LINES      8
#define   DEBUGACTUAL_WIDTH    100

#define DIGIA0 (23) // Port 1 pin 5 (yellow)
#define DIGIA1 (18) // Port 1 pin 6 (blue)

#define DIGIB0 (28) // Port 2 pin 5
#define DIGIB1 (19) // Port 2 pin 6

#define DIGIC0 (29) // Port 3 pin 5
#define DIGIC1 (20) // Port 3 pin 6

#define DIGID0 (30) // Port 4 pin 5
#define DIGID1 (2)  // Port 4 pin 6
// See HW appendix page 1. Pin5 on port 1 is PA18 that is DIGIA1
#define LEDVAL_ (1 << DIGIA0)
// Little function to toggle a pin
// Usage: write {togglepin(0);}
//   in your code to turn off the led
ULONG myspinner;
#define togglepin(toggle)\
{/* GPIO register addresses */\
	/* Register use */\
	*AT91C_PIOA_PER = LEDVAL_;\
	*AT91C_PIOA_OER = LEDVAL_;\
	if(toggle == 0)\
	  *AT91C_PIOA_CODR = LEDVAL_;  /* port 1 pin 5 at 0.0 v (enable this line OR the next)*/\
	else if(toggle == 1)\
	  *AT91C_PIOA_SODR = LEDVAL_;  /* port 1 pin 5 (blue) at 3.25-3.27 v (GND is on pin 2 (black)) */\
	while(1){}; /* stop here */\
}

/* Repeately toggles the pin. 1000000 gives a visual difference */
#define spinpin(factor)\
{/* GPIO register addresses */\
  /* Register use */\
  *AT91C_PIOA_PER = LEDVAL_;\
  *AT91C_PIOA_OER = LEDVAL_;\
  while(1){\
    myspinner = factor * 1000000;\
    while(myspinner--){\
      *AT91C_PIOA_CODR = LEDVAL_;  /* port 1 pin 5 at 0.0 v (enable this line OR the next)*/\
    }\
    myspinner = factor * 1000000;\
    while(myspinner--){\
      *AT91C_PIOA_SODR = LEDVAL_;  /* port 1 pin 5 (blue) at 3.25-3.27 v (GND is on pin 2 (black)) */\
    }\
  }\
}

static UBYTE DebugString[50] =  {0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
                                 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
                                 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
                                 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
                                 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00};

static UBYTE DebugLine[100];

static FONT DebugFont =
	{
	  0x04,0x00, // Graphics Format
	  0x02,0x40, // Graphics DataSize
	  0x10,      // Graphics Count X
	  0x06,      // Graphics Count Y
	  0x06,      // Graphics Width
	  0x08,      // Graphics Height
	  {0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x06,0x5F,0x06,0x00,0x00,0x07,0x03,0x00,0x07,0x03,0x00,0x24,0x7E,0x24,0x7E,0x24,0x00,0x24,0x2B,0x6A,0x12,0x00,0x00,0x63,0x13,0x08,0x64,0x63,0x00,0x30,0x4C,0x52,0x22,0x50,0x00,0x00,0x07,0x03,0x00,0x00,0x00,0x00,0x3E,0x41,0x00,0x00,0x00,0x00,0x41,0x3E,0x00,0x00,0x00,0x08,0x3E,0x1C,0x3E,0x08,0x00,0x08,0x08,0x3E,0x08,0x08,0x00,0x80,0x60,0x60,0x00,0x00,0x00,0x08,0x08,0x08,0x08,0x08,0x00,0x00,0x60,0x60,0x00,0x00,0x00,0x20,0x10,0x08,0x04,0x02,0x00,
	  0x3E,0x51,0x49,0x45,0x3E,0x00,0x00,0x42,0x7F,0x40,0x00,0x00,0x62,0x51,0x49,0x49,0x46,0x00,0x22,0x49,0x49,0x49,0x36,0x00,0x18,0x14,0x12,0x7F,0x10,0x00,0x2F,0x49,0x49,0x49,0x31,0x00,0x3C,0x4A,0x49,0x49,0x30,0x00,0x01,0x71,0x09,0x05,0x03,0x00,0x36,0x49,0x49,0x49,0x36,0x00,0x06,0x49,0x49,0x29,0x1E,0x00,0x00,0x6C,0x6C,0x00,0x00,0x00,0x00,0xEC,0x6C,0x00,0x00,0x00,0x08,0x14,0x22,0x41,0x00,0x00,0x24,0x24,0x24,0x24,0x24,0x00,0x00,0x41,0x22,0x14,0x08,0x00,0x02,0x01,0x59,0x09,0x06,0x00,
	  0x3E,0x41,0x5D,0x55,0x1E,0x00,0x7E,0x11,0x11,0x11,0x7E,0x00,0x7F,0x49,0x49,0x49,0x36,0x00,0x3E,0x41,0x41,0x41,0x22,0x00,0x7F,0x41,0x41,0x41,0x3E,0x00,0x7F,0x49,0x49,0x49,0x41,0x00,0x7F,0x09,0x09,0x09,0x01,0x00,0x3E,0x41,0x49,0x49,0x7A,0x00,0x7F,0x08,0x08,0x08,0x7F,0x00,0x00,0x41,0x7F,0x41,0x00,0x00,0x30,0x40,0x40,0x40,0x3F,0x00,0x7F,0x08,0x14,0x22,0x41,0x00,0x7F,0x40,0x40,0x40,0x40,0x00,0x7F,0x02,0x04,0x02,0x7F,0x00,0x7F,0x02,0x04,0x08,0x7F,0x00,0x3E,0x41,0x41,0x41,0x3E,0x00,
	  0x7F,0x09,0x09,0x09,0x06,0x00,0x3E,0x41,0x51,0x21,0x5E,0x00,0x7F,0x09,0x09,0x19,0x66,0x00,0x26,0x49,0x49,0x49,0x32,0x00,0x01,0x01,0x7F,0x01,0x01,0x00,0x3F,0x40,0x40,0x40,0x3F,0x00,0x1F,0x20,0x40,0x20,0x1F,0x00,0x3F,0x40,0x3C,0x40,0x3F,0x00,0x63,0x14,0x08,0x14,0x63,0x00,0x07,0x08,0x70,0x08,0x07,0x00,0x71,0x49,0x45,0x43,0x00,0x00,0x00,0x7F,0x41,0x41,0x00,0x00,0x02,0x04,0x08,0x10,0x20,0x00,0x00,0x41,0x41,0x7F,0x00,0x00,0x04,0x02,0x01,0x02,0x04,0x00,0x80,0x80,0x80,0x80,0x80,0x00,
	  0x00,0x02,0x05,0x02,0x00,0x00,0x20,0x54,0x54,0x54,0x78,0x00,0x7F,0x44,0x44,0x44,0x38,0x00,0x38,0x44,0x44,0x44,0x28,0x00,0x38,0x44,0x44,0x44,0x7F,0x00,0x38,0x54,0x54,0x54,0x08,0x00,0x08,0x7E,0x09,0x09,0x00,0x00,0x18,0x24,0xA4,0xA4,0xFC,0x00,0x7F,0x04,0x04,0x78,0x00,0x00,0x00,0x00,0x7D,0x40,0x00,0x00,0x40,0x80,0x84,0x7D,0x00,0x00,0x7F,0x10,0x28,0x44,0x00,0x00,0x00,0x00,0x7F,0x40,0x00,0x00,0x7C,0x04,0x18,0x04,0x78,0x00,0x7C,0x04,0x04,0x78,0x00,0x00,0x38,0x44,0x44,0x44,0x38,0x00,
	  0xFC,0x44,0x44,0x44,0x38,0x00,0x38,0x44,0x44,0x44,0xFC,0x00,0x44,0x78,0x44,0x04,0x08,0x00,0x08,0x54,0x54,0x54,0x20,0x00,0x04,0x3E,0x44,0x24,0x00,0x00,0x3C,0x40,0x20,0x7C,0x00,0x00,0x1C,0x20,0x40,0x20,0x1C,0x00,0x3C,0x60,0x30,0x60,0x3C,0x00,0x6C,0x10,0x10,0x6C,0x00,0x00,0x9C,0xA0,0x60,0x3C,0x00,0x00,0x64,0x54,0x54,0x4C,0x00,0x00,0x08,0x3E,0x41,0x41,0x00,0x00,0x00,0x00,0x77,0x00,0x00,0x00,0x00,0x41,0x41,0x3E,0x08,0x00,0x02,0x01,0x02,0x01,0x00,0x00,0x10,0x20,0x40,0x38,0x07,0x00}
  };

UBYTE     DebugDisplayInitString[] =
{
  0xEB,   // LCD bias setting = 1/9         0xEB
  0x2F,   // Power control    = internal    0x2F
  0xA4,   // All points not on              0xA4
  0xA6,   // Not inverse                    0xA6
  0x40,   // Start line = 0                 0x40
  0x81,   // Electronic volume              0x81
  0x5A,   //      -"-                       0x5F
  0xC4,   // LCD mapping                    0xC4
  0x27,   // Set temp comp.                 0x27-
  0x29,   // Panel loading                  0x28    0-1
  0xA0,   // Framerate                      0xA0-
  0x88,   // CA++                           0x88-
  0x23,   // Multiplex 1:65                 0x23
  0xAF    // Display on                     0xAF
};

UBYTE     DebugDisplayLineString[DEBUGDISP_LINES][3] =
{
  { 0xB0,0x10,0x00 },
  { 0xB1,0x10,0x00 },
  { 0xB2,0x10,0x00 },
  { 0xB3,0x10,0x00 },
  { 0xB4,0x10,0x00 },
  { 0xB5,0x10,0x00 },
  { 0xB6,0x10,0x00 },
  { 0xB7,0x10,0x00 }
};

extern UBYTE     DisplayWrite(UBYTE Type,UBYTE *pData,UWORD Length);

  ULONG waiti;
  ULONG waitj;

#define waitspin(count)	{\
  {\
		waiti = 0;\
		while(++waiti < count){\
			waitj=0;\
			while(++waitj < count);\
		}\
  }\
}



void ShowDebugString(){


  UBYTE   *str;
  UBYTE   *pSource;
  UBYTE   *pDestination;
  UBYTE   FontWidth;
  UBYTE   Line;
  UBYTE   Items;
  UBYTE   Item;
  FONT*   pFont;
  UBYTE   max, cnt;

  waitspin(10000);
  
  DisplayWrite(DEBUGCMD,(UBYTE*)DebugDisplayInitString,sizeof(DebugDisplayInitString));

  waitspin(10000);
  
  DisplayWrite(DEBUGCMD,(UBYTE*)DebugDisplayLineString[0],3);

  waitspin(10000);

  pFont = (FONT*)&DebugFont;
  
  max = DEBUGACTUAL_WIDTH;
  cnt = 0;
  
  //Clear line data
  memset(DebugLine, 0x00, sizeof(DebugLine));
  str          = DebugString;     
  Line         = 0;
  Items        = pFont->ItemsX * pFont->ItemsY;
  pDestination = (UBYTE*)&DebugLine[0];
  while (*str && ++cnt<DEBUGACTUAL_WIDTH)
  {
	Item           = *str - ' ';
	if (Item < Items)
	{
		FontWidth    = pFont->ItemPixelsX;
		pSource      = (UBYTE*)&pFont->Data[Item * FontWidth];
		while (FontWidth--)
		{
			*pDestination = *pSource;
			pDestination++;
			pSource++;
		}
	}
	str++;
  }
  
  
  DisplayWrite(DEBUGDAT,&DebugLine[0], DEBUGACTUAL_WIDTH); 
  
  //Stop and turn on light sensor on port 1
  togglepin(1);
}


//Example usages: Uncomment as needed

//#include "nxtdebug.r"  
//ULONG  DebugUL;
//ULONG* DebugULP;
//UWORD  DebugUW;
//UWORD* DebugUWP;
//UBYTE  DebugUB;
//UBYTE* DebugUBP;
//sprintf(DebugString,"NXTGCC %d.%d.%d", 0, 0, 12);
//sprintf(DebugString,"A: %p V: %#02x",DebugUBP,DebugUB);
//sprintf(DebugString,"Hej hej");
//sprintf(DebugString,"sizeof(UBYTE)=%d",sizeof(UBYTE));
//ShowDebugString();

