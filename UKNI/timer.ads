----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Timer
--  Stored Filename: $Id: Timer.ads 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Created By: D Curtis
--  <description>
--               This package control the main system timer
--  </description>
----------------------------------------------------------------------

with Mod_Types;

use type Mod_Types.Unsigned_8,
    Mod_Types.Unsigned_16;

--# inherit Mod_Types;

package Timer
--# own in  Timeout;
--#     out Setup;
is
   -------------------------------------------------------------------
   --  Types
   -------------------------------------------------------------------

   --  Number of seconds for a timer to tick for
   subtype Seconds_Type is Mod_Types.Unsigned_16 range 0 .. 3600;

   -------------------------------------------------------------------
   --  Subprograms
   -------------------------------------------------------------------

   -------------------------------------------------------------------
   --  <name> Init</name>
   --  <description>
   --               Setup timer 3 to overflow on second ticks, and enable
   --               interrupts to be used with the timer
   --  </description>
   --  <input name="None">
   --  </input>
   --  <output name="None">
   --  </output>
   -------------------------------------------------------------------
   procedure Init;
   --# global out Setup;
   --# derives Setup from ;
   pragma Inline (Init);

   -------------------------------------------------------------------
   --  <name> Set_Timeout_Seconds</name>
   --  <description>
   --               Reset the current timer to zero and setup the timer interval
   --  </description>
   --  <input name="The_Interval">
   --              The number of seconds to count to
   --  </input>
   --  <output name="None">
   --  </output>
   -------------------------------------------------------------------
   procedure Set_Timeout_Seconds (The_Interval : in Seconds_Type);
   --# global out Setup;
   --# derives Setup from The_Interval;
   pragma Inline (Set_Timeout_Seconds);

   -------------------------------------------------------------------
   --  <name> Check_Timeout</name>
   --  <description>
   --               Check to see if the timer has counted for the number of seconds
   --               set via the use of Set_Timeout_Seconds
   --  </description>
   --  <input name="None">
   --  </input>
   --  <Returns>
   --             True when the timer has counted for the selected number of seconds
   --  </Returns>
   -------------------------------------------------------------------
   function Check_Timeout return Boolean;
   --# global in Timeout;
   pragma Inline (Check_Timeout);

end Timer;
