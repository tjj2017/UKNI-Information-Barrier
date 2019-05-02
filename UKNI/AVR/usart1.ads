----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: usart1
--  Stored Filename: $Id: usart1.ads 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Under Review
--  Created By: D Berry
--  <description>
--               Hardware interface layer for communicating via usart1
--  *            Cut-down library file for use with the IB
--  </description>
----------------------------------------------------------------------

with Mod_Types,
     Usart_Types;

use type Mod_Types.Unsigned_8,
    Mod_Types.Unsigned_16,
    Mod_Types.Unsigned_32,
    Mod_Types.Unsigned_64;

--# inherit Mod_Types,
--#         Usart_Types;

package Usart1

is
   -------------------------------------------------------------------
   --  <name> Start_Up </name>
   --  <description> This is used to Initalise the USART.
   --                interest
   --  </description>
   --  <input name="UCSRB">
   --     The value to assign to UCSRB1
   --  *  Bit 7     6       5       4       3       2       1       0
   --  *  RXCIE   TXCIE   UDRIE   RXEN    TXEN   UCSZn2   RXB8n   TXB8n
   --  *  Value of 1 enables and 0 Disables these options
   --  *  RXCIE: Enable Recieve Complete Interrupt
   --  *  TXCIE: Enable Transmit Complete Interrupt
   --  *  UDRIE: Enable Data Register Empty
   --  *  RXEN: Recive enable
   --  *  TXEN: Transmit enable
   --  *  UCSZ2: bit 2 of Character Size
   --  *  RXB8: Recieved bit 9 (unavaliable in current software development)
   --  *  TXB8: Transmit bit 9 (unavaliable in current software development)
   --  </input><input name="UCSRC">
   --     The value to assign to UCSRC1
   --  *  Bit 7      6       5     4         3       2       1       0
   --  *  UMSELn1 UMSELn0 UPMn1 UPMn0     USBSn    UCSZn1  UCSZn0   UCPOLn
   --  *     0       0       0     0         0       1       1       0
   --  *  UMSEL: Usart Select Mode
   --  *   00      Asynchronous USART
   --  *   01      Synchronous Usart
   --  *   11      Master SPI MSPIM
   --  *  UPM: Usart Parity mode
   --  *   00 Disabled
   --  *   10 Even Parity
   --  *   11 odd Parity
   --  *  USBS :Usart Stop Bit Select
   --  *   0 - 1 Stop Bit
   --  *   1 - 2 Stop Bits
   --  </input><input name="Baud_Rate">
   --     Baud rate is to select the number relavent to the output frequencyMaximum error 0.2%
   --  *  Baud rate        8Mhz           16Mhz
   --  *  51              9600           19.2k
   --  *  25             19.2k           38.4k
   --  *  12             38.4k           76.8k
   --  *  1               250k           0.5M
   --  *  0               0.5M            1 M
   --  </input>
   --  <output name="None">
   --  </output>
   -------------------------------------------------------------------
   procedure Start_Up
     (UCSRB     : in Mod_Types.Unsigned_8;
      UCSRC     : in Mod_Types.Unsigned_8;
      Baud_Rate : in Mod_Types.Unsigned_8);
   --# derives null from Baud_Rate,
   --#                   UCSRB,
   --#                   UCSRC;
   pragma Inline (Start_Up);

   -------------------------------------------------------------------
   --  <name> Send_Message_8 </name>
   --  <description> Transmit a byte of data through the USART as ascii
   --  </description>
   --  <input name="Data">
   --     Byte to be transmitted
   --  </input>
   --  <output name="None">
   --  </output>
   -------------------------------------------------------------------
   procedure Send_Message_8 (Data : in Mod_Types.Unsigned_8);
   --# derives null from Data;
   pragma Inline (Send_Message_8);

   -------------------------------------------------------------------
   --  <name> Send_Message_16 </name>
   --  <description> Transmit a U16 of data through the USART as ascii
   --  </description>
   --  <input name="Data">
   --     U16 of data to be transmitted
   --  </input>
   --  <output name="None">
   --  </output>
   -------------------------------------------------------------------
   procedure Send_Message_16 (Data : in Mod_Types.Unsigned_16);
   --# derives null from Data;
   pragma Inline (Send_Message_16);

   -------------------------------------------------------------------
   --  <name> Send_Message_32 </name>
   --  <description> Transmit a U32 of data through the USART as ascii
   --  </description>
   --  <input name="Data">
   --     U32 of data to be transmitted
   --  </input>
   --  <output name="None">
   --  </output>
   -------------------------------------------------------------------
   procedure Send_Message_32 (Data : in Mod_Types.Unsigned_32);
   --# derives null from Data;
   pragma Inline (Send_Message_32);

   -------------------------------------------------------------------
   --  <name> Send_Message_64 </name>
   --  <description> Transmit a U64 of data through the USART as ascii
   --  </description>
   --  <input name="Data">
   --     U364 of data to be transmitted
   --  </input>
   --  <output name="None">
   --  </output>
   -------------------------------------------------------------------
   procedure Send_Message_64 (Data : in Mod_Types.Unsigned_64);
   --# derives null from Data;
   pragma Inline (Send_Message_64);

   -------------------------------------------------------------------
   --  <name> Send_Message_Comma </name>
   --  <description> This is used to transmit a comma
   --  *             For data separation.
   --  </description>
   --  <input name="None">
   --  </input>
   --  <output name="None">
   --  </output>
   -------------------------------------------------------------------
   procedure Send_Message_Comma;
   --# derives;
   --  This subprogram was missing from the git distribution and
   --  has been added by TJJ for ASVAT.  It may not work the same as
   --  the unknown functionality of the missing subprogram
   pragma Inline (Send_Message_Comma);

   -------------------------------------------------------------------
   --  <name> Send_Message_New_Line </name>
   --  <description> This is used to transmit a new line
   --  *             For data separation.
   --  </description>
   --  <input name="None">
   --  </input>
   --  <output name="None">
   --  </output>
   -------------------------------------------------------------------
   procedure Send_Message_New_Line;
   --# derives;
   pragma Inline (Send_Message_New_Line);

   -------------------------------------------------------------------
   --  <name> Send_Usart_1 </name>
   --  <description> Transmit a byte through the usart
   --  </description>
   --  <input name="value">
   --             Data to be sent
   --  </input>
   --  <output name="None">
   --  </output>
   -------------------------------------------------------------------
   procedure Send_Usart_1 (value : in Mod_Types.Unsigned_8);
   --# derives null from value;
   pragma Inline (Send_Usart_1);

   -------------------------------------------------------------------
   --  <name> Send_String </name>
   --  <description> Transmit a string of characters through the usart
   --  </description>
   --  <input name="Item">
   --             The string of characters to be sent
   --  </input>
   --  <output name="None">
   --  </output>
   -------------------------------------------------------------------
   procedure Send_String (Item : in String);
   --# derives null from Item;
   pragma Inline (Send_String);

private

   -------------------------------------------------------------------
   --  <name> Convert_To_String_8 </name>
   --  <description> This is used to convert the unsigned_8 into a string of
   --  *             charaters for transmission
   --  </description>
   --  <input name="invalue">
   --             value to be convereted
   --  </input>
   --  <output name="string3">
   --             String length 3 of ascii characters
   --  </output><output name="length">
   --             a value of the length of the Ascii string
   --  </output>
   -------------------------------------------------------------------
   procedure Convert_To_String_8
     (invalue : in Mod_Types.Unsigned_8;
      string3 : out Usart_Types.AStr3;
      length  : out Mod_Types.Unsigned_8);
   --# derives length,
   --#         string3 from invalue;
   pragma Inline (Convert_To_String_8);

   -------------------------------------------------------------------
   --  <name> Convert_To_String_16 </name>
   --  <description> This is used to convert the unsigned_16 into a string of
   --  *             charaters for transmission
   --  </description>
   --  <input name="invalue">
   --             value to be convereted
   --  </input>
   --  <output name="string3">
   --             String length 5 of ascii characters
   --  </output><output name="length">
   --             a value of the length of the Ascii string
   --  </output>
   -------------------------------------------------------------------
   procedure Convert_To_String_16
     (invalue : in Mod_Types.Unsigned_16;
      string5 : out Usart_Types.AStr5;
      length  : out Mod_Types.Unsigned_8);
   --# derives length,
   --#         string5 from invalue;
   pragma Inline (Convert_To_String_16);

   -------------------------------------------------------------------
   --  <name> Convert_To_String_32 </name>
   --  <description> This is used to convert the unsigned_32 into a string of
   --  *             charaters for transmission
   --  </description>
   --  <input name="invalue">
   --             value to be convereted
   --  </input>
   --  <output name="string3">
   --             String length 10 of ascii characters
   --  </output><output name="length">
   --             a value of the length of the Ascii string
   --  </output>
   -------------------------------------------------------------------
   procedure Convert_To_String_32
     (invalue  : in Mod_Types.Unsigned_32;
      string10 : out Usart_Types.AStr10;
      length   : out Mod_Types.Unsigned_8);
   --# derives length,
   --#         string10 from invalue;
   pragma Inline (Convert_To_String_32);

   -------------------------------------------------------------------
   --  <name> Convert_To_String_64 </name>
   --  <description> This is used to convert the unsigned_64 into a string of
   --  *             charaters for transmission
   --  </description>
   --  <input name="invalue">
   --             value to be convereted
   --  </input>
   --  <output name="string3">
   --             String length 20 of ascii characters
   --  </output><output name="length">
   --             a value of the length of the Ascii string
   --  </output>
   -------------------------------------------------------------------
   procedure Convert_To_String_64
     (invalue  : in Mod_Types.Unsigned_64;
      string20 : out Usart_Types.AStr20;
      length   : out Mod_Types.Unsigned_8);
   --# derives length,
   --#         string20 from invalue;
   pragma Inline (Convert_To_String_64);

   -------------------------------------------------------------------
   --  <name> Send_String_3 </name>
   --  <description> Transmit data of String 3 through the usart
   --  </description>
   --  <input name="Item">
   --             String to be sent
   --  </input><input name="length">
   --             Number of characters to send
   --  </input>
   --  <output name="None">
   --  </output>
   -------------------------------------------------------------------
   procedure Send_String_3
     (Item   : in Usart_Types.AStr3;
      Length : in Mod_Types.Unsigned_8);
   --# derives null from Item,
   --#                   Length;
   pragma Inline (Send_String_3);

   -------------------------------------------------------------------
   --  <name> Send_String_5 </name>
   --  <description> Transmit data of String 5 through the usart
   --  </description>
   --  <input name="Item">
   --             String to be sent
   --  </input><input name="length">
   --             Number of characters to send
   --  </input>
   --  <output name="None">
   --  </output>
   -------------------------------------------------------------------
   procedure Send_String_5
     (Item   : in Usart_Types.AStr5;
      Length : in Mod_Types.Unsigned_8);
   --# derives null from Item,
   --#                   Length;
   pragma Inline (Send_String_5);

   -------------------------------------------------------------------
   --  <name> Send_String_10 </name>
   --  <description> Transmit data of String 10 through the usart
   --  </description>
   --  <input name="Item">
   --             String to be sent
   --  </input><input name="length">
   --             Number of characters to send
   --  </input>
   --  <output name="None">
   --  </output>
   -------------------------------------------------------------------
   procedure Send_String_10
     (Item   : in Usart_Types.AStr10;
      Length : in Mod_Types.Unsigned_8);
   --# derives null from Item,
   --#                   Length;
   pragma Inline (Send_String_10);

   -------------------------------------------------------------------
   --  <name> Send_String_20 </name>
   --  <description> Transmit data of String 20 through the usart
   --  </description>
   --  <input name="Item">
   --             String to be sent
   --  </input><input name="length">
   --             Number of characters to send
   --  </input>
   --  <output name="None">
   --  </output>
   -------------------------------------------------------------------
   procedure Send_String_20
     (Item   : in Usart_Types.AStr20;
      Length : in Mod_Types.Unsigned_8);
   --# derives null from Item,
   --#                   Length;
   pragma Inline (Send_String_20);

end Usart1;
