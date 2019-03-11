----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: calibration.gain_adjustment
--  Stored Filename: $Id: calibration-gain_adjustment.adb 1 2012-11-23 08:36:13Z cmarsh
--  Status: Operational
--  Created By: D Curtis
--  Description: This private child package handles the interface to the gain attenuator
--               adjustment
----------------------------------------------------------------------
with Mod_Types,
     Registers,
     System.Storage_Elements,
     Usart1;

use type Mod_Types.Unsigned_8;

package body Calibration.Gain_Adjustment
--# own State is out Attenuator_Setting,
--#               Attenuator_Setting_Stored;
is
   -------------------------------------------------------------------
   --  Port Details
   -------------------------------------------------------------------
   subtype Attenuator_Setting_Type is Mod_Types.Unsigned_8; -- subtyped to aid clarity of code
   --  Initial value for the attenutor is based on mid-point of resistor settings
   ATTENUATOR_INITIAL_VALUE  : constant  := 128;
   Attenuator_Setting        : Attenuator_Setting_Type;  --  Active value to set the attenuators
   --  Attenuators are on PORTE of the AVR2560
   for Attenuator_Setting'Address use System.Storage_Elements.To_Address (Registers.PORTE);
   pragma Volatile (Attenuator_Setting);

   --  Data direction register for PORT E
   Attenuator_Setting_DDR    : constant Mod_Types.Unsigned_8 := Registers.DDR_OUTPUT;
   for Attenuator_Setting_DDR'Address use System.Storage_Elements.To_Address (Registers.DDRE);

   --  Value internal to software of the attenuators
   Attenuator_Setting_Stored : Mod_Types.Unsigned_8 := ATTENUATOR_INITIAL_VALUE;

   -------------------------------------------------------------------
   --  Name       : Output_Attenuator_Setting
   --  Implementation Information: Engineering use only
   -------------------------------------------------------------------
   procedure Output_Attenuator_Setting
   is
      --  This procedure is hidden because
      --  1. This procedure is for engineering use only and its assurance is
      --     not part of the evidance pack
      --  2. This procedure calls the usart1 package which contains directives
      --     below the SPARK layer of influence
      --# hide Output_Attenuator_Setting;
   begin
      Usart1.Send_String ("Current Attenuator Setting: ");
      Usart1.Send_Message_8 (Attenuator_Setting_Stored);
      Usart1.Send_Message_New_Line;
   end Output_Attenuator_Setting;

   -------------------------------------------------------------------
   --  Name       : Reset
   --  Implementation Information: Includes engineering use print statements.
   -------------------------------------------------------------------
   procedure Reset
   --# global out Attenuator_Setting;
   --#        out Attenuator_Setting_Stored;
   --# derives Attenuator_Setting,
   --#         Attenuator_Setting_Stored from ;
   is
   begin
      Attenuator_Setting_Stored := ATTENUATOR_INITIAL_VALUE;
      Attenuator_Setting := Attenuator_Setting_Stored;
      Output_Attenuator_Setting;
   end Reset;

   -------------------------------------------------------------------
   --  Name       : Adjust_Gain
   --  Implementation Information: Includes engineering use print statements.
   -------------------------------------------------------------------
   procedure Adjust_Gain
     (Peak_Location : in Channel_Types.Data_Channel_Number;
      Ideal_Channel : in Channel_Types.Data_Channel_Number)
   --# global in out Attenuator_Setting_Stored;
   --#           out Attenuator_Setting;
   --# derives Attenuator_Setting,
   --#         Attenuator_Setting_Stored from Attenuator_Setting_Stored,
   --#                                        Ideal_Channel,
   --#                                        Peak_Location;
   is
      --  type for calculating the number of channels to move the attenuators for
      subtype Error_Type is Integer range -Integer (Channel_Types.Data_Channel_Number'Last) ..
        Integer (Channel_Types.Data_Channel_Number'Last);

      --  value for the difference between ideal and peak location
      Channels_Of_Error : Error_Type;
   begin
      --  This procedure will adjust gain two steps on the attenuators for each
      --  channel of error on the peak location.
      --  we can therefore notionally shift the peak from channel 3667 to 3604 (+63 *2)
      --  or 3250 to 3604 (-64*2)

      Channels_Of_Error := Integer (Peak_Location) - Integer (Ideal_Channel);

      if Channels_Of_Error <= -Calibration.MIN_PEAK_VARIANCE or else
        (Integer (Attenuator_Setting_Stored) + 2 * Channels_Of_Error) <
           Integer (Mod_Types.Unsigned_8'First) then
         Attenuator_Setting_Stored := Mod_Types.Unsigned_8'First;
      elsif Channels_Of_Error >= Calibration.MAX_PEAK_VARIANCE or else
        (Integer (Attenuator_Setting_Stored) + 2 * Channels_Of_Error) >
          Integer (Mod_Types.Unsigned_8'Last) then
         Attenuator_Setting_Stored := 254; --  The attenuator setting must be even, therefore this is not 255
      else
         Attenuator_Setting_Stored := Mod_Types.Unsigned_8
           (Integer (Attenuator_Setting_Stored) + 2 * Channels_Of_Error);
      end if;

      --  Store the new attenuator setting and output the result.
      Attenuator_Setting := Attenuator_Setting_Stored;
      Output_Attenuator_Setting;
   end Adjust_Gain;

   -------------------------------------------------------------------
   --  Name       : Decrease
   --  Implementation Information: Includes engineering use print statements.
   -------------------------------------------------------------------
   procedure Decrease
   --# global in out Attenuator_Setting_Stored;
   --#           out Attenuator_Setting;
   --# derives Attenuator_Setting,
   --#         Attenuator_Setting_Stored from Attenuator_Setting_Stored;
   is
   begin
      if Attenuator_Setting_Stored < Attenuator_Setting_Type'Last then
         Attenuator_Setting_Stored := Attenuator_Setting_Stored + 1;
      end if;
      Attenuator_Setting := Attenuator_Setting_Stored;
      Output_Attenuator_Setting;
   end Decrease;

   -------------------------------------------------------------------
   --  Name       : Increase
   --  Implementation Information: Includes engineering use print statements.
   -------------------------------------------------------------------
   procedure Increase
   --# global in out Attenuator_Setting_Stored;
   --#           out Attenuator_Setting;
   --# derives Attenuator_Setting,
   --#         Attenuator_Setting_Stored from Attenuator_Setting_Stored;
   is
   begin
      if Attenuator_Setting_Stored > Attenuator_Setting_Type'First then
         Attenuator_Setting_Stored := Attenuator_Setting_Stored - 1;
      end if;
      Attenuator_Setting := Attenuator_Setting_Stored;
      Output_Attenuator_Setting;
   end Increase;

end Calibration.Gain_Adjustment;
