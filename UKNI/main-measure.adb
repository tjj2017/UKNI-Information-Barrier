----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Main.Measure
--  Stored Filename: $Id: Main-Measure.adb 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Created By: D Curtis
--  Description: Seperation of the measurement procedures from the main procedure
--  Implementation Information: Nested subprogram body from Main.adb
--                             separate files
----------------------------------------------------------------------
separate (Main)

-------------------------------------------------------------------
--  Name       : Measure
--  Implementation Information: None.
-------------------------------------------------------------------
procedure Measure

is
   --  Flag to state whether the measurement tests have passed
   Is_Present     : Boolean;

   --  Flag to state whether the source is active enough
   Count_In_Range : Boolean;
begin
   --  Clear all lit measurement and verification Indicators
   Indicator.Clear_Result_Indicator (Indicator_ID => Indicator.MEASUREMENT_PRESENT);
   Indicator.Clear_Result_Indicator (Indicator_ID => Indicator.MEASUREMENT_NOT_PROVEN);
   Indicator.Clear_Result_Indicator (Indicator_ID => Indicator.CALIBRATION_VERIFY_PASS);
   Indicator.Clear_Result_Indicator (Indicator_ID => Indicator.CALIBRATION_VERIFY_FAIL);

   --  Check that there are sufficient counts
   Count_Is_In_Range (In_Range => Count_In_Range);
   if Count_In_Range then
      --  If there are sufficient counts, check for Pu239 and check the Pu240:Pu239 ratio
      --# accept F, 10, Measurement.Data_Store,
      --# "Assignment ineffective as the store is always reset";
      Measurement.Perform_Measurement (Is_Present => Is_Present);
      --# end accept;

      --  Indicator the result of the Pu measurement
      if Is_Present then
         Indicator.Set_Result_Indicator (Indicator_ID => Indicator.MEASUREMENT_PRESENT);
      else
         Indicator.Set_Result_Indicator (Indicator_ID => Indicator.MEASUREMENT_NOT_PROVEN);
      end if;
   end if;

   --  Reset the measurement store to its default value
   Measurement.Clear_Store;
end Measure;
