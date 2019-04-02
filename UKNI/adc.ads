----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: ADC
--  Stored Filename: $Id: ADC.ads 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Created By: D Curtis
--  <description>
--               ADC interface package for collecting the gamma spectra
--  </description>
----------------------------------------------------------------------

with Channel_Types,
     Mod_Types;

use type Mod_Types.Unsigned_8,
    Mod_Types.Unsigned_16;

--# inherit Channel_Types,
--#         Mod_Types,
--#         Registers;

package ADC
--# own State;
--# initializes State;
is

   -------------------------------------------------------------------
   --  Subprograms
   -------------------------------------------------------------------

   -------------------------------------------------------------------
   --  <name> Check_Trigger_Edge</name>
   --  <description>
   --               Check whether a falling edge occured on the ADC busy line
   --  </description>
   --  <input name="None">
   --  </input>
   --  <output name="Triggered">
   --               Boolean flag stating whether a new reading has been detected
   --  </output>
   -------------------------------------------------------------------
   procedure Check_Trigger_Edge (Triggered : out Boolean);
   --# global in out State;
   --# derives State,
   --#         Triggered from State;
   pragma Inline (Check_Trigger_Edge);

   -------------------------------------------------------------------
   --  <name> Get_Reading</name>
   --  <description>
   --               Get the channel number corresponding to the reading recieved
   --  *            from the ADC
   --  </description>
   --  <input name="None">
   --  </input>
   --  <output name="Reading">
   --               Returns the channel number corresponding to the energy of
   --  *            the pulse detected by the ADC
   --  </output>
   -------------------------------------------------------------------
   procedure Get_Reading (Reading : out Channel_Types.Data_Channel_Number);
   --# global in out State;
   --# derives Reading,
   --#         State   from State;
   pragma Inline (Get_Reading);

private

   -------------------------------------------------------------------
   --  <name> Disable_ADC</name>
   --  <description>
   --               Disables the external ADC
   --  </description>
   --  <input name="None">
   --  </input>
   --  <output name="None">
   --  </output>
   -------------------------------------------------------------------
   procedure Disable_ADC;
   --# global in out State;
   --# derives State from *;
   pragma Inline (Disable_ADC);

   -------------------------------------------------------------------
   --  <name> Enable_ADC</name>
   --  <description>
   --               Enables the external ADC
   --  </description>
   --  <input name="None">
   --  </input>
   --  <output name="None">
   --  </output>
   -------------------------------------------------------------------
   procedure Enable_ADC;
   --# global in out State;
   --# derives State from *;
   pragma Inline (Enable_ADC);

   -------------------------------------------------------------------
   --  <name> Assemble_Reading</name>
   --  <description>
   --               Return the reading currently present on the external ADC
   --  </description>
   --  <input name="None">
   --  </input>
   --  <output name="Reading">
   --               Returns the channel number corresponding to the energy of
   --  *            the pulse detected by the ADC
   --  </output>
   -------------------------------------------------------------------
   procedure Assemble_Reading (Reading : out Channel_Types.Data_Channel_Number);
   --# global in out State;
   --# derives Reading,
   --#         State   from State;
   pragma Inline (Assemble_Reading);

end ADC;
