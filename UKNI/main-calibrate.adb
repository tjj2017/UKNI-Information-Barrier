----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: main.Calibrate
--  Stored Filename: $Id: main-calibrate.adb 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Created By: D Curtis
--  Description: Seperation of the calibration procedure from the main procedure
--  Implementation Information: Nested subprogram body from Main.adb
--                             separate files
----------------------------------------------------------------------

separate (Main)

-------------------------------------------------------------------
--  Name       : Calibrate
--  Implementation Information: None.
-------------------------------------------------------------------
procedure Calibrate (Is_Successful : out Boolean)

is
   --  Flag stating whether the source is active enough
   Count_In_Range : Boolean;
begin
   --  Clear the indicators to show that calibration has commenced
   Indicator.Clear_All_Result_Indicators;

   --  Run the check and indicate the result
   Count_Is_In_Range (In_Range => Count_In_Range);
   if Count_In_Range then
      Calibration.Perform_Calibration (Is_Successful => Is_Successful);
      if Is_Successful then
         Indicator.Set_Result_Indicator (Indicator_ID => Indicator.CALIBRATION_PASS);
      else
         Indicator.Set_Result_Indicator (Indicator_ID => Indicator.CALIBRATION_FAIL);
      end if;
   else
      Is_Successful := False;
   end if;

end Calibrate;
