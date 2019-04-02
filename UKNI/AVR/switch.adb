----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Switch
--  Stored Filename: $Id: Switch.adb 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Created By: D Curtis
--  Description: Control routines for the switches
----------------------------------------------------------------------

with Registers,
     System.Storage_Elements;

package body Switch
--#own State is
--#    in PORTINJ;
is

   -------------------------------------------------------------------
   --  Register Definitions
   -------------------------------------------------------------------

   --# accept W, 2, "Representation Clauses";
   PORTINJ : Mod_Types.Unsigned_8;
   for PORTINJ'Address use System.Storage_Elements.To_Address
     (Registers.PINJ);
   --# assert PORTINJ'Always_Valid;
   pragma Volatile (PORTINJ);

   DDRJ    : constant Mod_Types.Unsigned_8 := 2#01110000#; -- this port is shared with mode leds
   --# accept W, 351, DDRJ, "Constant with address clause";
   for DDRJ'Address use System.Storage_Elements.To_Address (Registers.DDRJ);
   --# end accept;
   --# end accept;

   -------------------------------------------------------------------
   --  Subprograms
   -------------------------------------------------------------------

   -------------------------------------------------------------------
   --  Name       : Get_Port_Value
   --  Implementation Information: None.
   -------------------------------------------------------------------
   function Get_Port_Value return  Mod_Types.Unsigned_8
   --# global in PORTINJ;
   --# return PORTINJ;
   is
   begin

      return PORTINJ;

   end Get_Port_Value;

   -------------------------------------------------------------------
   --  Name       : Check_Calibrate
   --  Implementation Information: None.
   -------------------------------------------------------------------
   function Check_Calibrate (Port_Value : in Mod_Types.Unsigned_8) return Boolean
   is
      The_Mode   : Boolean;
   begin
      if (Port_Value and 2#0000_0100#) = 0 then
         The_Mode := True;
      else
         The_Mode := False;
      end if;

      return The_Mode;
   end Check_Calibrate;

   -------------------------------------------------------------------
   --  Name       : Check_Measure
   --  Implementation Information: None.
   -------------------------------------------------------------------
   function Check_Measure (Port_Value : in Mod_Types.Unsigned_8) return Boolean
   is
      The_Mode   : Boolean;
   begin
      if (Port_Value and 2#0000_0010#) = 0 then
         The_Mode := True;
      else
         The_Mode := False;
      end if;

      return The_Mode;
   end Check_Measure;

   -------------------------------------------------------------------
   --  Name       : Check_Verify
   --  Implementation Information: None.
   -------------------------------------------------------------------
   function Check_Verify (Port_Value : in Mod_Types.Unsigned_8) return Boolean
   is
      The_Mode   : Boolean;
   begin
      if (Port_Value and 2#0000_0001#) = 0 then
         The_Mode := True;
      else
         The_Mode := False;
      end if;

      return The_Mode;
   end Check_Verify;

   -------------------------------------------------------------------
   --  Name       : Check_State
   --  Implementation Information: None.
   -------------------------------------------------------------------
   procedure Check_State (Selected_Switch : out Selection)
   --# global in PORTINJ;
   --# derives Selected_Switch from PORTINJ;
   is

      Port_Value             : Mod_Types.Unsigned_8;
      Calibrate_Switch_State : Boolean;
      Measure_Switch_State   : Boolean;
      Verify_Switch_State    : Boolean;
   begin
      --  Get the port value
      Port_Value := Get_Port_Value;

      --  Check whether any of the switches have been pressed
      Calibrate_Switch_State := Check_Calibrate (Port_Value => Port_Value);
      Measure_Switch_State   := Check_Measure (Port_Value => Port_Value);
      Verify_Switch_State    := Check_Verify (Port_Value => Port_Value);

      --  Set the output dependant on which switch has been pressed
      if Calibrate_Switch_State then
         Selected_Switch := Calibrate;
      elsif Measure_Switch_State then
         Selected_Switch := Measure;
      elsif Verify_Switch_State then
         Selected_Switch := Verify;
      else
         Selected_Switch := None;
      end if;
   end Check_State;

end Switch;
