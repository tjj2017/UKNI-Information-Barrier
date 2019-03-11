----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: calibration.gain_adjustment
--  Stored Filename: $Id: calibration-gain_adjustment.ads 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Created By: D Curtis
--  <description>
--               This private child package handles the interface to the gain attenuator
--               adjustment relays.
--  </description>
----------------------------------------------------------------------

with Channel_Types;

--# inherit Calibration,
--#         Channel_Types,
--#         Mod_Types,
--#         Registers;

private package Calibration.Gain_Adjustment
--# own State;
--# initializes State;
is

   -------------------------------------------------------------------
   --  Subprograms
   -------------------------------------------------------------------

   -------------------------------------------------------------------
   --  <name> Reset </name>
   --  <description>
   --               Resets the calibration attenuators to their default setting
   --  </description>
   --  <input name="None">
   --  </input>
   --  <output name="None">
   --  </output>
   -------------------------------------------------------------------
   procedure Reset;
   --# global in out State;
   --# derives State from *;
   pragma Inline (Reset);

   -------------------------------------------------------------------
   --  <name> Adjust_Gain </name>
   --  <description>
   --               A call to this procedure will attempt to move the calibration peak from
   --  *            the found location to the ideal channel. Due to hardware tolerances and
   --  *            statistical variations it may still be one or two channels out.
   --  *            It is recommended that progressive gain adjustments using the Increase/Decrease
   --  *            procedures are used to refine the calibration.
   --  </description>
   --  <input name="Peak_Location">
   --               The channel of the current peak location.
   --  </input><input name="Ideal_Channel">
   --               The channel where the peak is expected to be.
   --  </input>
   --  <output name="None">
   --  </output>
   -------------------------------------------------------------------
   procedure Adjust_Gain (Peak_Location : in Channel_Types.Data_Channel_Number;
                          Ideal_Channel : in Channel_Types.Data_Channel_Number);
   --# global in out State;
   --# derives State from *,
   --#                    Ideal_Channel,
   --#                    Peak_Location;
   pragma Inline (Adjust_Gain);

   -------------------------------------------------------------------
   --  <name> Increase </name>
   --  <description>
   --               Increase the gain setting by 1 bit.
   --  </description>
   --  <input name="None">
   --  </input>
   --  <output name="None">
   --  </output>
   -------------------------------------------------------------------
   procedure Increase;
   --# global in out State;
   --# derives State from *;
   pragma Inline (Increase);

   -------------------------------------------------------------------
   --  <name> Decrease </name>
   --  <description>
   --               Decrease the gain setting by 1 bit.
   --  </description>
   --  <input name="None">
   --  </input>
   --  <output name="None">
   --  </output>
   -------------------------------------------------------------------
   procedure Decrease;
   --# global in out State;
   --# derives State from *;
   pragma Inline (Decrease);

private

   -------------------------------------------------------------------
   --  <name> Output_Attenuator_Setting </name>
   --  <description>
   --               Send the attenuator settings to usart1.
   --  *            Engineering use only
   --  </description>
   --  <input name="None">
   --  </input>
   --  <output name="None">
   --  </output>
   -------------------------------------------------------------------
   procedure Output_Attenuator_Setting;
   --#derives;
   pragma Inline (Output_Attenuator_Setting);
end Calibration.Gain_Adjustment;
