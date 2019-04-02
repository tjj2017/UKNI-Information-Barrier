----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Main
--  Stored Filename: $Id: Main.adb 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Description: Main program for the UKNI IB running on the physical phase 3 hardware
--  Implementation Information: Note nested subprogram bodies in
--                             separate files
----------------------------------------------------------------------

with Calibration,
     Count_Range_Check,
     Indicator,
     Measurement,
     Memory_Checks,
     Mod_Types,
     Switch,
     Timer,
     Usart1;

--# inherit ADC,
--#         Calibration,
--#         Count_Range_Check,
--#         Indicator,
--#         Measurement,
--#         Measurement_Peaks,
--#         Memory_Checks,
--#         Mod_Types,
--#         Switch,
--#         Timeouts,
--#         Timer,
--#         Usart_Types,
--#         Usart1;

--# Main_Program;

-------------------------------------------------------------------
--  Name        : Main
--  Description : Run the UKNI IB
--  Inputs      : None.
--  Outputs     : None.
-------------------------------------------------------------------
procedure Main
--# global in     Count_Range_Check.Counter;
--#        in     Switch.State;
--#        in     Timer.Timeout;
--#        in out ADC.State;
--#        in out Calibration.State;
--#        in out Indicator.Result;
--#        in out Measurement_Peaks.State;
--#           out Indicator.Mode;
--#           out Measurement.Data_Store;
--#           out Timer.Setup;
--# derives ADC.State,
--#         Indicator.Mode,
--#         Measurement.Data_Store,
--#         Timer.Setup             from ADC.State,
--#                                      Count_Range_Check.Counter,
--#                                      Switch.State,
--#                                      Timer.Timeout &
--#         Calibration.State,
--#         Measurement_Peaks.State from *,
--#                                      ADC.State,
--#                                      Calibration.State,
--#                                      Count_Range_Check.Counter,
--#                                      Switch.State,
--#                                      Timer.Timeout &
--#         Indicator.Result        from *,
--#                                      ADC.State,
--#                                      Calibration.State,
--#                                      Count_Range_Check.Counter,
--#                                      Measurement_Peaks.State,
--#                                      Switch.State,
--#                                      Timer.Timeout;

is
   --  Enumeration type variable indicating which switch has been pressed whilst the
   --  switch is being monitored.  The switch is only check when the system is not
   --  performing an active operation.
   Selected_Switch : Switch.Selection;

   --  The calibration status of the IB, set to not calibrated by default
   Is_Calibrated   : Boolean := False;

   --  Variable for storing the result of a count range check which can be called prior to
   --  calibration to assist with source setup, this procedure allows count rate display via usart
   Unused          : Boolean;

   -------------------------------------------------------------------
   --  Name        : Count_Is_In_Range
   --  Description : Run a count range check to ensure that a viable activity source
   --                is present
   --  Inputs      : None.
   --  Outputs     : In_Range - Whether a viable source is present.
   -------------------------------------------------------------------
   procedure Count_Is_In_Range (In_Range : out Boolean)
   --# global in     Count_Range_Check.Counter;
   --#        in     Timer.Timeout;
   --#           out Timer.Setup;
   --# derives In_Range    from Count_Range_Check.Counter,
   --#                          Timer.Timeout &
   --#         Timer.Setup from ;
   is separate;

   -------------------------------------------------------------------
   --  Name        : Calibrate
   --  Description : Run the calibration routine and indicate the result
   --  Inputs      : None.
   --  Outputs     : Is_Successful - Whether calibration was successful or not.
   -------------------------------------------------------------------
   procedure Calibrate (Is_Successful : out Boolean)
   --# global in     Count_Range_Check.Counter;
   --#        in     Timer.Timeout;
   --#        in out ADC.State;
   --#        in out Calibration.State;
   --#        in out Indicator.Result;
   --#           out Timer.Setup;
   --# derives ADC.State,
   --#         Calibration.State,
   --#         Indicator.Result  from *,
   --#                                ADC.State,
   --#                                Count_Range_Check.Counter,
   --#                                Timer.Timeout &
   --#         Is_Successful,
   --#         Timer.Setup       from ADC.State,
   --#                                Count_Range_Check.Counter,
   --#                                Timer.Timeout;
   is separate;

   -------------------------------------------------------------------
   --  Name        : Measure
   --  Description : Run the measurement routine and indicate the result
   --  Inputs      : None.
   --  Outputs     : None.
   -------------------------------------------------------------------
   procedure Measure
   --# global in     Calibration.State;
   --#        in     Count_Range_Check.Counter;
   --#        in     Timer.Timeout;
   --#        in out ADC.State;
   --#        in out Indicator.Result;
   --#        in out Measurement_Peaks.State;
   --#           out Measurement.Data_Store;
   --#           out Timer.Setup;
   --# derives ADC.State               from *,
   --#                                      Count_Range_Check.Counter,
   --#                                      Timer.Timeout &
   --#         Indicator.Result,
   --#         Measurement_Peaks.State from *,
   --#                                      ADC.State,
   --#                                      Calibration.State,
   --#                                      Count_Range_Check.Counter,
   --#                                      Measurement_Peaks.State,
   --#                                      Timer.Timeout &
   --#         Measurement.Data_Store  from  &
   --#         Timer.Setup             from Count_Range_Check.Counter,
   --#                                      Timer.Timeout;
   --# post Measurement.Is_Empty_PF(Measurement.Data_Store);
   is separate;

   -------------------------------------------------------------------
   --  Name        : Verify_Calibration
   --  Description : Run the calibration verificaiton routine and indicate the result
   --  Inputs      : None.
   --  Outputs     : None.
   -------------------------------------------------------------------
   procedure Verify_Calibration
   --# global in     Count_Range_Check.Counter;
   --#        in     Timer.Timeout;
   --#        in out ADC.State;
   --#        in out Calibration.State;
   --#        in out Indicator.Result;
   --#           out Timer.Setup;
   --# derives ADC.State,
   --#         Calibration.State from *,
   --#                                ADC.State,
   --#                                Count_Range_Check.Counter,
   --#                                Timer.Timeout &
   --#         Indicator.Result  from *,
   --#                                ADC.State,
   --#                                Calibration.State,
   --#                                Count_Range_Check.Counter,
   --#                                Timer.Timeout &
   --#         Timer.Setup       from Count_Range_Check.Counter,
   --#                                Timer.Timeout;
   is separate;

   -------------------------------------------------------------------
   --  Name        : Power_On_Lamp_Test
   --  Description : Illuminate and extinguish the illuminators in order to
   --                indicate to the user whether the indicators are working
   --  Inputs      : None.
   --  Outputs     : None.
   -------------------------------------------------------------------
   procedure Power_On_Lamp_Test
   --# global in     Timer.Timeout;
   --#        in out Indicator.Result;
   --#           out Indicator.Mode;
   --#           out Timer.Setup;
   --# derives Indicator.Mode,
   --#         Timer.Setup      from  &
   --#         Indicator.Result from * &
   --#         null             from Timer.Timeout;
   is separate;

   -------------------------------------------------------------------
   --  Name        : Memory_Test
   --  Description : Run a CRC check on the flash and a PBIT on the RAM
   --  Inputs      : None.
   --  Outputs     : Whether the memory tests passed or failed.
   -------------------------------------------------------------------
   procedure Memory_Test (Result : out Boolean)
   --# derives Result from ;
   is separate;

   -------------------------------------------------------------------
   --  Name        : Initialize
   --  Description : Run start-up functionality required by the IB
   --  Inputs      : None.
   --  Outputs     : None.
   -------------------------------------------------------------------
   procedure Initialize
   --# global in     Timer.Timeout;
   --#        in out Calibration.State;
   --#        in out Indicator.Result;
   --#           out Indicator.Mode;
   --#           out Measurement.Data_Store;
   --#           out Timer.Setup;
   --# derives Calibration.State,
   --#         Indicator.Result       from * &
   --#         Indicator.Mode,
   --#         Measurement.Data_Store,
   --#         Timer.Setup            from  &
   --#         null                   from Timer.Timeout;
   --# post Measurement.Is_Empty_PF(Measurement.Data_Store);
   is separate;

begin
   --  Note operation continues regardless of the tests passing or failing
   Initialize;

   loop
      --  infinite loop awaiting a button press to selected IB Mode
      Switch.Check_State (Selected_Switch => Selected_Switch);
      --# assert Measurement.Is_Empty_PF(Measurement.Data_Store);

      case Selected_Switch is
         when Switch.Calibrate =>
            --  Calibration indication and routine
            Indicator.Set_Current_Mode_Indicator (Indicator_ID => Indicator.CALIBRATION_MODE);
            Calibrate (Is_Successful => Is_Calibrated);

            Indicator.Clear_All_Mode_Indicators;
            Usart1.Send_Message_New_Line;
         when Switch.Measure =>
            --  Measurement indication and routine
            --  Can only be called if the system is calibrated
            if Is_Calibrated then
                  Indicator.Set_Current_Mode_Indicator (Indicator_ID => Indicator.MEASUREMENT_MODE);
                  Measure;
                  Indicator.Clear_All_Mode_Indicators;
                  Usart1.Send_Message_New_Line;
            end if;
         when Switch.Verify =>
            --  Calibration verification indication and routine
            --  Verification occurs if the system has previously been calibrated
            if Is_Calibrated then
               Indicator.Set_Current_Mode_Indicator (Indicator_ID => Indicator.CALIBRATION_VERIFY_MODE);
               Verify_Calibration;
               Indicator.Clear_All_Mode_Indicators;
               Usart1.Send_Message_New_Line;
            else
               --  If the system has not been calibrated this procedure allows
               --  a count rate display via to uart to assist with source setup
               --# accept f, 10, Unused, "Unused assignment of parameter" &
               --#        f, 33, Unused, "Unused assignment of parameter";
               Count_Is_In_Range (In_Range => Unused);

            end if;
         when Switch.None =>
            --  If no switch has been pressed, countinue awaiting a switch press.
            null;
      end case;

   end loop;

end Main;
