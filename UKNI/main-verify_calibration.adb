----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Main.Verify_Calibration
--  Stored Filename: $Id: main-verify_calibration.adb 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Date Created:
--  Description: Seperation of the calibration verification procedure from the main proceduree
--  Implementation Information: Nested subprogram body from Main.adb
--                             separate files
----------------------------------------------------------------------
separate (Main)

-------------------------------------------------------------------
--  Name       : Verify_Calibration
--  Implementation Information: None.
-------------------------------------------------------------------
procedure Verify_Calibration

is
   --  Boolean flag indicating whether the verification was successful
   Is_Successful  : Boolean;

   --  Boolean flag indicating whether there were enough counts to perform the verification
   Count_In_Range : Boolean;
begin
   --  Clear the calibration verification indicators
   Indicator.Clear_Result_Indicator (Indicator_ID => Indicator.CALIBRATION_VERIFY_PASS);
   Indicator.Clear_Result_Indicator (Indicator_ID => Indicator.CALIBRATION_VERIFY_FAIL);

   --  Check for sufficient counts and then verify the calibration is still valid
   Count_Is_In_Range (In_Range => Count_In_Range);
   if Count_In_Range then
      Calibration.Verify_Calibration (Is_Successful => Is_Successful);
      if Is_Successful then
         Indicator.Set_Result_Indicator (Indicator_ID => Indicator.CALIBRATION_VERIFY_PASS);
      else
         Indicator.Set_Result_Indicator (Indicator_ID => Indicator.CALIBRATION_VERIFY_FAIL);
      end if;
   end if;
end Verify_Calibration;
