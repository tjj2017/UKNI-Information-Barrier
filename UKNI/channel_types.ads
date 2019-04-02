----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Channel_Types
--  Stored Filename: $Id: Channel_Types.ads 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Created By: D Curtis
--  <description>
--               This package contains types and constants associated
--               with the number of ADC channels
--  </description>
----------------------------------------------------------------------

with Mod_Types,
     Toolbox;

use type Mod_Types.Unsigned_16,
    Mod_Types.Unsigned_64;

--# inherit Mod_Types,
--#         Toolbox;

package Channel_Types is

   -------------------------------------------------------------------
   --  Constants
   -------------------------------------------------------------------

   --  A 12 bit ADC is being used for the IB
   NUMBER_ADC_CHANNELS : constant := 2 ** 12;

   -------------------------------------------------------------------
   --  Types
   -------------------------------------------------------------------

   --  Type associated with the number of ADC values
   subtype Data_Channel_Number is Mod_Types.Unsigned_16 range
      0 .. NUMBER_ADC_CHANNELS - 1;

   --  Some of the maths needs to be done on parts of a channel
   --  The extended channel type is to incorporate this extra accuracy
   subtype Extended_Channel_Type is Mod_Types.Unsigned_64 range
     0 .. Mod_Types.Unsigned_64 (Data_Channel_Number'Last) * Toolbox.MULT;

end Channel_Types;
