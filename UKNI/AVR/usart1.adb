----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
-------------------------------------------------------------------------------
--  Name: USART Control System
--  Stored Filename: $Id: usart1.adb 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Date Created:07/05/08
--  Description:  Hardware interface layer for communicating via usart1
--                Cut-down library file for use with the IB
-------------------------------------------------------------------------------

with System;

package body Usart1

is
--# hide Usart1;
--  Package body hidden due to low level nature not being meaningful at the
--  higher layer, and the number of register accesses that correspond to key
--  functionality

   ----------------------------------------------------
   ----------AVR ATMEGA 2560 USART1 Memory Setup-------
   ----------------------------------------------------
   --  Spark Representation of UDR0
   --  USART 0 Data Register
   --  Allows in/out access
   UDR1_OUT : Mod_Types.Unsigned_8;
   for UDR1_OUT'Address use System'To_Address (16#CE#);
   pragma Volatile (UDR1_OUT);
   UDR1_IN : Mod_Types.Unsigned_8;
   for UDR1_IN'Address use System'To_Address (16#CE#);
   pragma Volatile (UDR1_IN);

   --  Spark Representation of UCSR1A
   --  USART 1 Control and Status Register A
   --  Allows in/out access
   UCSR1A_OUT : Mod_Types.Unsigned_8;
   for UCSR1A_OUT'Address use System'To_Address (16#C8#);
   pragma Volatile (UCSR1A_OUT);
   UCSR1A_IN : Mod_Types.Unsigned_8;
   for UCSR1A_IN'Address use System'To_Address (16#C8#);
   pragma Volatile (UCSR1A_IN);

   --  Spark Representation of UCSR0B register
   --  USART 0 Control and Status Register B
   --  Allows in/out access
   UCSR1B_OUT : Mod_Types.Unsigned_8;
   for UCSR1B_OUT'Address use System'To_Address (16#C9#);
   pragma Volatile (UCSR1B_OUT);
   UCSR1B_IN : Mod_Types.Unsigned_8;
   for UCSR1B_IN'Address use System'To_Address (16#C9#);
   pragma Volatile (UCSR1B_IN);

   --  Spark Representation of UCSR0C register
   --  USART 0 Control and Status Register C
   --  Allows in/out access
   UCSR1C_OUT : Mod_Types.Unsigned_8;
   for UCSR1C_OUT'Address use System'To_Address (16#CA#);
   pragma Volatile (UCSR1C_OUT);
   UCSR1C_IN : Mod_Types.Unsigned_8;
   for UCSR1C_IN'Address use System'To_Address (16#CA#);
   pragma Volatile (UCSR1C_IN);

   --  Spark Representation of UBRR1H register
   --  USART Baud Rate Registers High
   --  Allows out access
   UBRR1H_OUT : Mod_Types.Unsigned_8;
   for UBRR1H_OUT'Address use System'To_Address (16#CD#);
   pragma Volatile (UBRR1H_OUT);

   --  Spark Representation of UBRR0L register
   --  USART Baud Rate Registers Low
   --  Allows out access
   UBRR1L_OUT : Mod_Types.Unsigned_8;
   for UBRR1L_OUT'Address use System'To_Address (16#CC#);
   pragma Volatile (UBRR1L_OUT);
   ----------------------------------------------------
   ------------End of ATMega 2560 USART0 Setup---------
   ----------------------------------------------------

   -------------------------------------------------------------------
   --  Subprograms
   -------------------------------------------------------------------

   -------------------------------------------------------------------
   --  Name: Start up
   --  Implementation Information: None
   -------------------------------------------------------------------
   procedure Start_Up (UCSRB     : in Mod_Types.Unsigned_8;
                       UCSRC     : in Mod_Types.Unsigned_8;
                       Baud_Rate : in Mod_Types.Unsigned_8)
   is

   begin
      UCSR1A_OUT := 16#00#;
      UCSR1B_OUT := UCSRB;
      UCSR1C_OUT := UCSRC;
      UBRR1L_OUT := Baud_Rate;
      UBRR1H_OUT := 16#00#;

   end Start_Up;

   -------------------------------------------------------------------
   --  Name: Send_Usart_1
   --  Implementation Information: None
   -------------------------------------------------------------------
   procedure Send_Usart_1 (value : in Mod_Types.Unsigned_8)
   is
      --  variable used to track if send buffer is empty
      Data_Empty : Mod_Types.Unsigned_8;
   begin
      --  Wait till ready to send;
      loop
         Data_Empty := UCSR1A_IN;

         Data_Empty := Data_Empty and 2#00100000#;

         exit when Data_Empty = 2#00100000#;

      end loop;

      UDR1_OUT := value;

   end Send_Usart_1;

   -------------------------------------------------------------------
   --  Name: Convert to string 8
   --  Implementation Information: None
   -------------------------------------------------------------------
   procedure Convert_To_String_8
     (invalue : in Mod_Types.Unsigned_8;
      string3 : out Usart_Types.AStr3;
      length  : out Mod_Types.Unsigned_8)
   is
      --  Temporary store of the input string
      store      : Mod_Types.Unsigned_8;

      --  Reverse version of the string calculate during creation of the output
      RevString3 : Usart_Types.AStr3;

      --  Temporary counter
      j          : Usart_Types.s3_index;
   begin
      length     := 0;
      string3    := Usart_Types.AStr3'(others => 0);
      RevString3 := Usart_Types.AStr3'(others => 0);
      store      := invalue;

      for i in Usart_Types.s3_index loop
         RevString3 (i) := (store rem 10) + 48;
         --  48(ascii adjust to numbers)
         --  48 = 0 in characters
         store          := store / 10;
         if store = 0 then
            --  length limits size of string. Transmit relevent details only
            length := i;
            exit;
         end if;
      end loop;

      j := 1;
      for k in reverse Usart_Types.s3_index range string3'First .. length loop
         string3 (j) := RevString3 (k);
         j           := j + 1;
      end loop;

   end Convert_To_String_8;

   -------------------------------------------------------------------
   --  Name: Convert to string 16
   --  Implementation Information: None
   -------------------------------------------------------------------
   procedure Convert_To_String_16
     (invalue : in Mod_Types.Unsigned_16;
      string5 : out Usart_Types.AStr5;
      length  : out Mod_Types.Unsigned_8)
   is
      --  Temporary store of the input string
      store      : Mod_Types.Unsigned_16;

      --  Reverse version of the string calculate during creation of the output
      RevString5 : Usart_Types.AStr5;

      --  Temporary counter
      j          : Usart_Types.s5_index;
   begin
      store      := invalue;
      length     := 0;
      string5    := Usart_Types.AStr5'(others => 0);
      RevString5 := Usart_Types.AStr5'(others => 0);

      for i in Usart_Types.s5_index loop
         --  Remainder can never be above 9 9+48 <255
         RevString5 (i) := (Mod_Types.Unsigned_8 (store rem 10) + 48);
         --  48(ascii adjust to numbers)
         --  48 = 0 in characters
         store          := store / 10;
         if store = 0 then
            --  length limits size of string. Transmit relevent details only
            length := i;
            exit;
         end if;
      end loop;

      j := 1;
      for k in reverse Usart_Types.s5_index range string5'First .. length loop

         string5 (j) := RevString5 (k);
         j           := j + 1;
      end loop;
   end Convert_To_String_16;

   -------------------------------------------------------------------
   --  Name: Convert to string 32
   --  Implementation Information: None
   -------------------------------------------------------------------
   procedure Convert_To_String_32
     (invalue  : in Mod_Types.Unsigned_32;
      string10 : out Usart_Types.AStr10;
      length   : out Mod_Types.Unsigned_8)
   is
      --  Temporary store of the input string
      store       : Mod_Types.Unsigned_32;

      --  Reverse version of the string calculate during creation of the output
      RevString10 : Usart_Types.AStr10;

      --  Temporary counter
      j           : Usart_Types.s10_index;
   begin
      store       := invalue;
      length      := 0;
      string10    := Usart_Types.AStr10'(others => 0);
      RevString10 := Usart_Types.AStr10'(others => 0);

      for i in Usart_Types.s10_index loop
         --  Remainder can never be above 9 9+48 <255
         RevString10 (i) := (Mod_Types.Unsigned_8 (store rem 10) + 48);
         --  48(ascii adjust to numbers)
         --  48 = 0 in characters
         store           := store / 10;
         if store = 0 then
            --  length limits size of string. Transmit relevent details only
            length := i;
            exit;
         end if;
      end loop;

      j := 1;
      for k in reverse Usart_Types.s10_index range string10'First .. length loop
         string10 (j) := RevString10 (k);
         j            := j + 1;
      end loop;

   end Convert_To_String_32;

   -------------------------------------------------------------------
   --  Name: Convert to string 64
   --  Implementation Information: None
   -------------------------------------------------------------------
   procedure Convert_To_String_64
     (invalue  : in Mod_Types.Unsigned_64;
      string20 : out Usart_Types.AStr20;
      length   : out Mod_Types.Unsigned_8)
   is
      --  Temporary store of the input string
      store       : Mod_Types.Unsigned_64;

      --  Reverse version of the string calculate during creation of the output
      RevString20 : Usart_Types.AStr20;

      --  Temporary counter
      j           : Usart_Types.s20_index;
   begin
      store       := invalue;
      length      := 0;
      string20    := Usart_Types.AStr20'(others => 0);
      RevString20 := Usart_Types.AStr20'(others => 0);

      for i in Usart_Types.s20_index loop
         --  Remainder can never be above 9 9+48 <255
         RevString20 (i) := (Mod_Types.Unsigned_8 (store rem 10) + 48);
         --  48(ascii adjust to numbers)
         --  48 = 0 in characters
         store           := store / 10;
         if store = 0 then
            --  length limits size of string. Transmit relevent details only
            length := i;
            exit;
         end if;

      end loop;

      j := 1;
      for k in reverse Usart_Types.s20_index range string20'First .. length loop
         string20 (j) := RevString20 (k);
         j            := j + 1;
      end loop;

   end Convert_To_String_64;

   --------------------------------------------------------------------
   --  Name: Send_String_3
   --  Implementation Information: None
   --------------------------------------------------------------------
   procedure Send_String_3 (Item   : in Usart_Types.AStr3;
                            Length : in Mod_Types.Unsigned_8)
   is

   begin
      for I in Mod_Types.Unsigned_8 range Item'First .. Length loop
         Send_Usart_1 (value => Item (I));
      end loop;
   end Send_String_3;

   --------------------------------------------------------------------
   --  Name: Send_String_5
   --  Implementation Information: None
   --------------------------------------------------------------------
   procedure Send_String_5 (Item   : in Usart_Types.AStr5;
                            Length : in Mod_Types.Unsigned_8)
   is

   begin
      for I in Mod_Types.Unsigned_8 range Item'First .. Length loop
         Send_Usart_1 (value => Item (I));
      end loop;
   end Send_String_5;

   --------------------------------------------------------------------
   --  Name: Send_String_10
   --  Implementation Information: None
   --------------------------------------------------------------------
   procedure Send_String_10 (Item   : in Usart_Types.AStr10;
                             Length : in Mod_Types.Unsigned_8)
   is

   begin
      for I in Mod_Types.Unsigned_8 range Item'First .. Length loop
         Send_Usart_1 (value => Item (I));

      end loop;
   end Send_String_10;

   --------------------------------------------------------------------
   --  Name: Send_String_20
   --  Implementation Information: None
   --------------------------------------------------------------------
   procedure Send_String_20 (Item   : in Usart_Types.AStr20;
                             Length : in Mod_Types.Unsigned_8)
   is
   begin

      for I in Mod_Types.Unsigned_8 range Item'First .. Length loop
         Send_Usart_1 (value => Item (I));
      end loop;

   end Send_String_20;

   --------------------------------------------------------------------
   --  Name: Send_Message_8
   --  Implementation Information: None
   --------------------------------------------------------------------
   procedure Send_Message_8 (Data : in Mod_Types.Unsigned_8)
   is
      --  String of Maximum Length 3 to be sent through usart
      Item   : Usart_Types.AStr3;

      --  number of digits.
      Length : Mod_Types.Unsigned_8;
   begin

      Convert_To_String_8 (invalue => Data,
                           string3 => Item,
                           length => Length);

      Send_String_3 (Item   => Item,
                     Length => Length);

   end Send_Message_8;

   --------------------------------------------------------------------
   --  Name: Send_Message_new_Line
   --  Implementation Information: None
   --------------------------------------------------------------------
   procedure Send_Message_New_Line
   is
   begin
      Send_Usart_1 (value => 13);
   end Send_Message_New_Line;

   --------------------------------------------------------------------
   --  Name: Send_Message_16
   --  Implementation Information: None
   --------------------------------------------------------------------
   procedure Send_Message_16 (Data : in Mod_Types.Unsigned_16)
   is
      --  String of Maximum Length 5 to be sent through usart
      Item   : Usart_Types.AStr5;

      --  number of digits.
      Length : Mod_Types.Unsigned_8;
   begin

      Convert_To_String_16 (invalue  => Data,
                            string5  => Item,
                            length   => Length);

      Send_String_5 (Item   => Item,
                     Length => Length);

   end Send_Message_16;

   --------------------------------------------------------------------
   --  Name: Send_Message_32
   --  Implementation Information: None
   --------------------------------------------------------------------
   procedure Send_Message_32 (Data : in Mod_Types.Unsigned_32)
   is
      --  String of maximum length 10 to be sent through the USART
      Item   : Usart_Types.AStr10;

      --  Length value how many digits the number being transmitted is.
      Length : Mod_Types.Unsigned_8;

   begin

      Convert_To_String_32 (invalue  => Data,
                            string10 => Item,
                            length   => Length);

      Send_String_10 (Item   => Item,
                      Length => Length);

   end Send_Message_32;

   --------------------------------------------------------------------
   --  Name: Send_Message_32
   --  Implementation Information: None
   --------------------------------------------------------------------
   procedure Send_Message_64 (Data : in Mod_Types.Unsigned_64)
   is
      --  String of maximum length 10 to be sent through the USART
      Item   : Usart_Types.AStr20;

      --  Length value how many digits the number beingtransmitted is.
      Length : Mod_Types.Unsigned_8;

   begin

      Convert_To_String_64 (invalue  => Data,
                            string20 => Item,
                            length   => Length);

      Send_String_20 (Item   => Item,
                      Length => Length);

   end Send_Message_64;

   --------------------------------------------------------------------
   --  Name: Send_String
   --  Implementation Information: None
   --------------------------------------------------------------------
   procedure Send_String (Item : in String)
   is
   begin

      for I in Positive range Item'First .. Item'Last loop
         Send_Usart_1 (value => Character'Pos (Item (I)));
      end loop;

   end Send_String;

end Usart1;
