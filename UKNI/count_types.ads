----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Count_Types
--  Stored Filename: $Id: Count_Types.ads 140 2016-02-03 12:34:43Z CMarsh $$
--  Status: Operational
--  Created By: D Curtis
--  <description>
--               This package provides types and constants associated
--               with the calibration and measurement counts. The
--               constants effectively determine the limits on the
--               amount of data collected.
--  </description>
----------------------------------------------------------------------

with Mod_Types;

--# inherit Mod_Types;

package Count_Types is

   -------------------------------------------------------------------
   --  Constants
   -------------------------------------------------------------------

   --  Maximum number of counts captured in a channel during calibration
   MAX_CALIBRATION_COUNTS : constant := 8_000;

   --  Maximum number of counts captured in a channel during measurement
   MAX_MEASUREMENT_COUNTS : constant := 65_535;

   -------------------------------------------------------------------
   --  Types
   -------------------------------------------------------------------

   --  Type corresponding to the maximum channel size during calibration
   subtype Calibration_Count_Type is Mod_Types.Unsigned_16 range 0 .. MAX_CALIBRATION_COUNTS;

   --  Type corresponding to the maximum channel size during measurement
   subtype Measurement_Count_Type is Mod_Types.Unsigned_16 range 0 .. MAX_MEASUREMENT_COUNTS;
end Count_Types;
