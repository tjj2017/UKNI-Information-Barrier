----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Switch
--  Stored Filename: $Id: Switch.ads 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Created By: D Curtis
--  <description>
--               This package access to the switches
--  </description>
----------------------------------------------------------------------

with Mod_Types;

use type Mod_Types.Unsigned_8;

--# inherit Mod_Types,
--#         Registers;

package Switch
--# own in State : Switches_State_Type;

is
   -------------------------------------------------------------------
   --  Types
   -------------------------------------------------------------------

   --# type Switches_State_Type is abstract;

   --  type naming the switches
   type Selection is (Calibrate, Measure, Verify, None);

   -------------------------------------------------------------------
   --  Subprograms
   -------------------------------------------------------------------

   -------------------------------------------------------------------
   --  <name> Check_State</name>
   --  <description>
   --               Check whether a switch has been selected
   --  </description>
   --  <input name="None">
   --  </input>
   --  <output name="Selected_Switch">
   --             The selected switch
   --  </output>
   -------------------------------------------------------------------
   procedure Check_State (Selected_Switch : out Selection);
   --# global in State;
   --# derives Selected_Switch from State;

private

   -------------------------------------------------------------------
   --  <name> Get_Port_Value</name>
   --  <description>
   --               Returns the current status of the port containing the switches
   --  </description>
   --  <input name="None">
   --  </input>
   --  <Returns>
   --             The switches' port value
   --  </Returns>
   -------------------------------------------------------------------
   function Get_Port_Value return  Mod_Types.Unsigned_8;
   --# global in State;

   -------------------------------------------------------------------
   --  <name> Check_Calibrate</name>
   --  <description>
   --               Returns whether the calibrate switch has been pressed
   --  </description>
   --  <input name="None">
   --  </input>
   --  <Returns>
   --             True if the calibrate switch has been pressed
   --  </Returns>
   -------------------------------------------------------------------
   function Check_Calibrate (Port_Value : in Mod_Types.Unsigned_8) return Boolean;
   --# return Result => ((Port_Value and 2#00000100#) = 0) <-> Result;
   pragma Inline (Check_Calibrate);

   -------------------------------------------------------------------
   --  <name> Check_Measure</name>
   --  <description>
   --               Returns whether the measure switch has been pressed
   --  </description>
   --  <input name="None">
   --  </input>
   --  <Returns>
   --             True if the measure switch has been pressed
   --  </Returns>
   -------------------------------------------------------------------
   function Check_Measure (Port_Value : in Mod_Types.Unsigned_8) return Boolean;
   --# return Result => ((Port_Value and 2#00000010#) = 0) <-> Result;
   pragma Inline (Check_Measure);

   -------------------------------------------------------------------
   --  <name> Check_Verify</name>
   --  <description>
   --               Returns whether the verify switch has been pressed
   --  </description>
   --  <input name="None">
   --  </input>
   --  <Returns>
   --             True if the verify switch has been pressed
   --  </Returns>
   -------------------------------------------------------------------
   function Check_Verify (Port_Value : in Mod_Types.Unsigned_8) return Boolean;
   --# return Result => ((Port_Value and 2#0000_0001#) = 0) <-> Result;
   pragma Inline (Check_Verify);

end Switch;
