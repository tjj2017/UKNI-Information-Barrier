----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Count_Range_Check
--  Stored Filename: $Id: Count_Range_Check.adb 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Created By: D Curtis
--  Description: Performs an activity check on the source
----------------------------------------------------------------------

with Mod_Types,
     System,
     Timeouts,
     Timer,
     Usart1;

use type Mod_Types.Unsigned_8,
         Mod_Types.Unsigned_16;

package body Count_Range_Check is
   --# hide Count_Range_Check;

   --  Package body hidden due to low level nature not being meaningful at the
   --  higher layer, and the number of register accesses that correspond to key
   --  functionality

   -------------------------------------------------------------------
   --  Register Definitions
   -------------------------------------------------------------------

   --  Timer Interrupt Mask Register
   TIMSK1       : Mod_Types.Unsigned_8;
   for TIMSK1'Address use System'To_Address (16#6F#);
   pragma Volatile (TIMSK1);

   --  Timer Counter Control Registers
   TCCR1A       : Mod_Types.Unsigned_8;
   for TCCR1A'Address use System'To_Address (16#80#);
   pragma Volatile (TCCR1A);
   TCCR1B       : Mod_Types.Unsigned_8;
   for TCCR1B'Address use System'To_Address (16#81#);
   pragma Volatile (TCCR1B);
   TCCR1C       : Mod_Types.Unsigned_8;
   for TCCR1C'Address use System'To_Address (16#82#);
   pragma Volatile (TCCR1C);

   --  Timer Counter Register High and Low
   TCNT1H       : Mod_Types.Unsigned_8;
   for TCNT1H'Address use System'To_Address (16#85#);
   pragma Volatile (TCNT1H);
   TCNT1L       : Mod_Types.Unsigned_8;
   for TCNT1L'Address use System'To_Address (16#84#);
   pragma Volatile (TCNT1L);

   --  Timer Counter Interrupt Flag Register
   TIFR1        : Mod_Types.Unsigned_8;
   for TIFR1'Address use System'To_Address (16#36#);
   pragma Volatile (TIFR1);

   -------------------------------------------------------------------
   --  Name       : Check_Count
   --  Implementation Information: Includes engineering use print statements.
   -------------------------------------------------------------------
   procedure Check_Count (In_Range : out Boolean)
   is
      --  Bolean flag for use in determining the wait required for the activity check
      Is_Timed_Out   : Boolean;

      --  Counter for timer 1 and local variables holding the register values
      TCNT1H_Read    : Mod_Types.Unsigned_8;
      TCNT1L_Read    : Mod_Types.Unsigned_8;
      Count          : Mod_Types.Unsigned_16 := 0;

      --  Local variable for use in determining whether the counter has overflown
      Timer_Overflow : Mod_Types.Unsigned_8;

      --  Definition of the maximum and minimum acceptable counts for the activity
      --  of the source
      MAX_COUNTS     : constant := 50_000;
      MIN_COUNTS     : constant := 50;

      -------------------------------------------------------------------
      --  Name: Initialize_Timer1
      --  Description: Initialize timer 1 such that it counts the number of
      --               changes on its input pin.  The timer register counts the
      --               number input received from the detector
      --  Input: None
      --  Output: None
      -------------------------------------------------------------------
      procedure Initialize_Timer1
      is
      begin
         --  Ensure that the timer 1 interrupts are disabled
         TIMSK1 := 0;

         --  Set up the timer to operate to count up on the falling edge
         --  of the tn pin.  Do not clear the counter and don't force a
         --  compare.
         TCCR1A := 0;
         TCCR1B := 2#0000_0110#;
         TCCR1C := 0;

         --  Set the timer 1 counter to 0
         TCNT1H := 0;
         TCNT1L := 0;

         --  reset timer overflow flag
         TIFR1 := TIFR1 or 2#0000_0001#;
      end Initialize_Timer1;

   begin
      Usart1.Send_String ("Performing Count Range Check:");
      Usart1.Send_Message_New_Line;

      --  Initialise timer 1 to count the activity of the source
      Initialize_Timer1;

      --  Initialise timer 3 and delay for detector busy seconds
      Timer.Init;
      Timer.Set_Timeout_Seconds (The_Interval => Timeouts.DETECTOR_BUSY);
      Is_Timed_Out := Timer.Check_Timeout;
      while not Is_Timed_Out loop
         Is_Timed_Out := Timer.Check_Timeout;
      end loop;

      --  Read the number of counts recorded in detector busy seconds
      TCNT1L_Read := TCNT1L;
      TCNT1H_Read := TCNT1H;
      Count := Mod_Types.Unsigned_16 (TCNT1H_Read) * 256 + Mod_Types.Unsigned_16 (TCNT1L_Read);

      --  Check to see whether timer 1 has overflown, and check whether the counts
      --  are in the allowable range.
      Timer_Overflow  := TIFR1 and 2#0000_0001#;
      if Count >= MIN_COUNTS and
        Count <= MAX_COUNTS and
        Timer_Overflow = 2#0000_0000# then
         In_Range := True;
         Usart1.Send_String ("Count in range");
         Usart1.Send_Message_New_Line;
      else
         In_Range := False;
         Usart1.Send_String ("Count out of range");
         Usart1.Send_Message_New_Line;
      end if;

      --  Report the number of counts received
      Usart1.Send_String ("Number of Counts: ");
      Usart1.Send_Message_16 (Count);
      Usart1.Send_Message_New_Line;
   end Check_Count;

end Count_Range_Check;
