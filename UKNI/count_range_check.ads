----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Count_Range_Check
--  Stored Filename: $Id: Count_Range_Check.ads 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Created By: D Curtis
--  <description>
--               Performs an activity check on the source
--  </description>
----------------------------------------------------------------------

--# inherit Mod_Types,
--#         Timeouts,
--#         Timer,
--#         Usart_Types,
--#         Usart1;

package Count_Range_Check
--# own Counter;
--# initializes Counter;
is
   -------------------------------------------------------------------
   --  Subprograms
   -------------------------------------------------------------------

   -------------------------------------------------------------------
   --  <name> Check_Count</name>
   --  <description>
   --               Perform a check of the activity of the source
   --  </description>
   --  <input name="None">
   --  </input>
   --  <output name="In_Range">
   --               True if the activity check has been passed.
   --  </output>
   -------------------------------------------------------------------
   procedure Check_Count (In_Range : out Boolean);
   --# global in     Counter;
   --#        in     Timer.Timeout;
   --#           out Timer.Setup;
   --# derives In_Range    from Counter,
   --#                          Timer.Timeout &
   --#         Timer.Setup from ;

end Count_Range_Check;
