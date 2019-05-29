-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--  ASVAT 3-May-2019 timer.shw
--  This a shadow file which replaces timer.adb for ASVAT analysis since the
--  distributed package body uses low-level hardware features not handled
--  by the basic gnat compiler or ASVAT.
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Timer
--  Stored Filename: $Id: timer.adb 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Created By: D Curtis
--  Description: This package control the main system timer
----------------------------------------------------------------------

with System.Machine_Code;

package body Timer
is

   -------------------------------------------------------------------
   --  Register Definitions
   -------------------------------------------------------------------
   --# hide Timer;

   --  Package body hidden due to low level nature not being meaningful at the
   --  higher layer, and the number of register accesses that correspond to key
   --  functionality

   Timeout : Boolean;
   pragma Volatile (Timeout); -- needed as otherwise optimised out

   --  Top value of the timer
   ICR3H         : Mod_Types.Unsigned_8;
   for ICR3H'Address use System'To_Address (16#97#);
   pragma Volatile (ICR3H);

   ICR3L         : Mod_Types.Unsigned_8;
   for ICR3L'Address use System'To_Address (16#96#);
   pragma Volatile (ICR3L);

   --  Timer interrupt mask
   TIMSK3        : Mod_Types.Unsigned_8;
   for TIMSK3'Address use System'To_Address (16#71#);
   pragma Volatile (TIMSK3);

   --  Timer mode
   TCCR3A        : Mod_Types.Unsigned_8;
   for TCCR3A'Address use System'To_Address (16#90#);
   pragma Volatile (TCCR3A);

   TCCR3B        : Mod_Types.Unsigned_8;
   for TCCR3B'Address use System'To_Address (16#91#);
   pragma Volatile (TCCR3B);

   --  Current count on the header
   TCNT3H        : Mod_Types.Unsigned_8;
   for TCNT3H'Address use System'To_Address (16#95#);
   pragma Volatile (TCNT3H);

   TCNT3L        : Mod_Types.Unsigned_8;
   for TCNT3L'Address use System'To_Address (16#94#);
   pragma Volatile (TCNT3L);

   -------------------------------------------------------------------
   --  Variables
   -------------------------------------------------------------------

   --  The number of whole seconds passed since the timer was last set
   Seconds_Count : Seconds_Type := 0;
   pragma Volatile (Seconds_Count);

   --  The number of seconds to count to
   Interval      : Seconds_Type;
   pragma Volatile (Interval);

   -------------------------------------------------------------------
   --  Interrupts
   -------------------------------------------------------------------

   -------------------------------------------------------------------
   --  Name: Timer_Interrupt
   --  Description: Declare an interrupt handler for timer3 capture event.
   --  Outputs: Seconds_Count - The number of whole seconds passed since the timer was last set
   --           Timeout       - Boolean flag stating whether the timer has reached its target
   --                           number of seconds
   -------------------------------------------------------------------

   --  ASVAT remove timer interrupt subprogram association.
   --  ASVAT does not handle Machine_Attributes or non-Ada languages
--     procedure Timer_Interrupt;
--     pragma Machine_Attribute (Timer_Interrupt, "signal");
--     pragma Export (C, Timer_Interrupt, "__vector_timer3_capt");

   procedure Timer_Interrupt is
   begin
      Seconds_Count := Seconds_Count + 1;
      if Seconds_Count = Interval then
         Timeout := True;
      end if;
   end Timer_Interrupt;

   -------------------------------------------------------------------
   --  Subprograms
   -------------------------------------------------------------------

   -------------------------------------------------------------------
   --  Name       : Init
   --  Implementation Information: Enables global interrupts.
   -------------------------------------------------------------------
   procedure Init is

   begin
      --  AVSAT - the source of this subprogram has been replaced by a null
      --  statement as it contains assembler statements not analyzed by
      --  AVSAT

      null;

      --  AVSAT removed
      --  The call to this procedure was to initialise the timer hardware
      --  Set timer input capture
--        ICR3H := 16#38#;    -- These registers set the  -- for 14.745MHz clock
--        ICR3L := 16#3F#;    -- "Top" value of the timer
--
--        --  Enable Input Capture interrupt.
--        TIMSK3 := 16#20#;
--
--        --  Set Timer 3 Mode.
--        TCCR3A := 16#00#;
--        TCCR3B := 16#1D#; -- xxxxx101 means clk div by 1024
--
--        --  Enable global interrupts.
--        System.Machine_Code.Asm ("sei", Volatile => True);
--
--        --  reset the timer counter
--        TCNT3H := 0;
--        TCNT3L := 0;
   end Init;

   -------------------------------------------------------------------
   --  Name       : Set_Timeout_Seconds
   --  Implementation Information: None.
   -------------------------------------------------------------------
   procedure Set_Timeout_Seconds (The_Interval : in Seconds_Type) is
   begin
      --  reset the timer counter
      TCNT3H := 0;
      TCNT3L := 0;

      --  reset the number of seconds that has elapsed
      Seconds_Count := 0;

      --  Setup the number of seconds to count for
      Interval      := The_Interval;

      --  Reset the timeout flag to false (not elapsed)
      Timeout       := False;
   end Set_Timeout_Seconds;

   -------------------------------------------------------------------
   --  Name       : Check_Timeout
   --  Implementation Information: None.
   -------------------------------------------------------------------
   function Check_Timeout return Boolean is
   begin
      return Timeout;
   end Check_Timeout;

end Timer;
