----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Calibration_Peak
--  Stored Filename: $Id: Calibration_Peak.ads 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Created By: D Curtis
--  <description>
--               Package container for the definition of a peak
--  </description>
----------------------------------------------------------------------

with Channel_Types;
--# inherit Channel_Types;

package Calibration_Peak is

   -------------------------------------------------------------------
   --  Constants
   -------------------------------------------------------------------

   ------------------- Calibration Peak Definitions-------------------
   --  These values are based on a channel resolution of 0.216keV

   --  Centre channel for lower calibration peak
   EU152_121_CENTRE_CHANNEL : constant := 563;

   --  Centre channel for upper calibration peak
   EU152_778_CENTRE_CHANNEL : constant := 3603;

   -------------------------------------------------------------------
   --  Types
   -------------------------------------------------------------------

   --  Integer offset to adjust the expected channel of the calibration peak
   subtype Offset_Type is Integer range -20 .. 20;

   --  ASVAT declare missing type.  This is probably not the same as the
   --  mising type declaration.
   subtype Cal_Offset_Type is Offset_Type;

   --  Type definition of a peak
   type Peak_Record_Type is
      record

         Centre_Channel             : Channel_Types.Data_Channel_Number;

         Search_Region_Low_Channel  : Channel_Types.Data_Channel_Number;

         Search_Region_High_Channel : Channel_Types.Data_Channel_Number;

      end record;

end Calibration_Peak;
