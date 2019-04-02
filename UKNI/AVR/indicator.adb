----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Indicator
--  Stored Filename: $Id: Indicator.adb 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Created By: D Curtis
--  Description: Control routines for the indicators
----------------------------------------------------------------------

with Mod_Types,
     Registers,
     System.Storage_Elements;

use type Mod_Types.Unsigned_8;

package body Indicator
--# own Result is out Result_PortK,
--#                   Result_PortK_Stored &
--#     Mode is out Mode_PortJ;
is

   -------------------------------------------------------------------
   --  Register Definitions
   -------------------------------------------------------------------

   --  Registers associated with the control of the results indicators
   --# accept W, 2, "Representation Clauses";
   Result_PortK       : Mod_Types.Unsigned_8;
   for Result_PortK'Address use
     System.Storage_Elements.To_Address (Registers.PORTK);
   pragma Volatile (Result_PortK);

   Result_PortK_Stored : Mod_Types.Unsigned_8 := 16#FF#;

   RESULT_DDRK         : constant Mod_Types.Unsigned_8 := Registers.DDR_OUTPUT;
   --# accept W, 351, RESULT_DDRK, "Constant with address clause";
   for RESULT_DDRK'Address use
     System.Storage_Elements.To_Address (Registers.DDRK);
   --# end accept;

   Mode_PortJ          : Mod_Types.Unsigned_8;
   for Mode_PortJ'Address use
     System.Storage_Elements.To_Address (Registers.PORTJ);
   pragma Volatile (Mode_PortJ);

   MODE_DDRJ           : constant Mod_Types.Unsigned_8 := 2#01110000#; -- this port is shared with switches
   --# accept W, 351, MODE_DDRJ, "Constant with address clause";
   for MODE_DDRJ'Address use
     System.Storage_Elements.To_Address (Registers.DDRJ);
   --# end accept;
   --# end accept;

   -------------------------------------------------------------------
   --  Types
   -------------------------------------------------------------------

   --  bitwise representation of the indicators to aid control

   type Result_Indicator_Bit_Number_Array_Type is
     array (Result_Indicator_Type) of Mod_Types.Unsigned_8;

   type Mode_Indicator_Bit_Number_Array_Type is
     array (Mode_Indicator_Type) of Mod_Types.Unsigned_8;

   -------------------------------------------------------------------
   --  Constants
   -------------------------------------------------------------------

   --  constant declaration of the location of the results indicators
   RESULT_INDICATOR_TO_UNSIGNED8 : constant
     Result_Indicator_Bit_Number_Array_Type :=
      Result_Indicator_Bit_Number_Array_Type'
     (CALIBRATION_PASS            => 1,
      CALIBRATION_FAIL            => 2,
      MEASUREMENT_PRESENT         => 4,
      MEASUREMENT_NOT_PROVEN      => 8,
      CALIBRATION_VERIFY_PASS     => 16,
      CALIBRATION_VERIFY_FAIL     => 32);
   --# for RESULT_INDICATOR_TO_UNSIGNED8 declare NoRule;

   --  constant declaration of the location of the mode indicators
   MODE_INDICATOR_TO_UNSIGNED8 : constant Mode_Indicator_Bit_Number_Array_Type
      :=
      Mode_Indicator_Bit_Number_Array_Type'
     (CALIBRATION_MODE        => 2#0100_0000#,
      MEASUREMENT_MODE        => 2#0010_0000#,
      CALIBRATION_VERIFY_MODE => 2#0001_0000#);
   --# for MODE_INDICATOR_TO_UNSIGNED8 declare NoRule;

   -------------------------------------------------------------------
   --  Subprograms
   -------------------------------------------------------------------

   -------------------------------------------------------------------
   --  Name       : Set_Result_Indicator
   --  Implementation Information: None.
   -------------------------------------------------------------------
   procedure Set_Result_Indicator (Indicator_ID : in Result_Indicator_Type)
   --# global in out Result_PortK_Stored;
   --#           out Result_PortK;
   --# derives Result_PortK,
   --#         Result_PortK_Stored from Indicator_ID,
   --#                                  Result_PortK_Stored;
   is
   begin
      Result_PortK_Stored :=
        ((RESULT_INDICATOR_TO_UNSIGNED8 (Indicator_ID)) or
         (Result_PortK_Stored));
      Result_PortK        := Result_PortK_Stored;
   end Set_Result_Indicator;

   -------------------------------------------------------------------
   --  Name       : Clear_Result_Indicator
   --  Implementation Information: None.
   -------------------------------------------------------------------
   procedure Clear_Result_Indicator
     (Indicator_ID : in Result_Indicator_Type)
   --# global in out Result_PortK_Stored;
   --#           out Result_PortK;
   --# derives Result_PortK,
   --#         Result_PortK_Stored from Indicator_ID,
   --#                                  Result_PortK_Stored;
   is
   begin
      Result_PortK_Stored :=
        ((not RESULT_INDICATOR_TO_UNSIGNED8 (Indicator_ID)) and
         (Result_PortK_Stored));
      Result_PortK        := Result_PortK_Stored;
   end Clear_Result_Indicator;

   -------------------------------------------------------------------
   --  Name       : Clear_All_Result_Indicators
   --  Implementation Information: None.
   -------------------------------------------------------------------
   procedure Clear_All_Result_Indicators
      --# global out Result_PortK;
      --#        out Result_PortK_Stored;
      --# derives Result_PortK,
      --#         Result_PortK_Stored from ;
   is
   begin
      Result_PortK_Stored := 16#00#;
      Result_PortK        := 16#00#;
   end Clear_All_Result_Indicators;

   -------------------------------------------------------------------
   --  Name       : Set_All_Result_Indicators
   --  Implementation Information: None.
   -------------------------------------------------------------------
   procedure Set_All_Result_Indicators
   --# global out Result_PortK;
   --#        out Result_PortK_Stored;
   --# derives Result_PortK,
   --#         Result_PortK_Stored from ;
   is
   begin
      Result_PortK_Stored := 2#0011_1111#;
      Result_PortK        := Result_PortK_Stored;
   end Set_All_Result_Indicators;

   -------------------------------------------------------------------
   --  Name       : Set_All_Mode_Indicators
   --  Implementation Information: None.
   -------------------------------------------------------------------
   procedure Set_All_Mode_Indicators
   --# global out Mode_PortJ;
   --# derives Mode_PortJ from ;
   is
   begin
      Mode_PortJ := 2#0111_0000#;
   end Set_All_Mode_Indicators;

   -------------------------------------------------------------------
   --  Name       : Set_Current_Mode_Indicator
   --  Implementation Information: None.
   -------------------------------------------------------------------
   procedure Set_Current_Mode_Indicator
     (Indicator_ID : in Mode_Indicator_Type)
   --# global out Mode_PortJ;
   --# derives Mode_PortJ from Indicator_ID;
   is
   begin
      Mode_PortJ := MODE_INDICATOR_TO_UNSIGNED8 (Indicator_ID);
   end Set_Current_Mode_Indicator;

   -------------------------------------------------------------------
   --  Name       : Clear_All_Mode_Indicators
   --  Implementation Information: None.
   -------------------------------------------------------------------
   procedure Clear_All_Mode_Indicators
   --# global out Mode_PortJ;
   --# derives Mode_PortJ from ;
   is
   begin
      Mode_PortJ        := 16#00#;
   end Clear_All_Mode_Indicators;

   -------------------------------------------------------------------
   --  Name       : Clear_All_Indicators
   --  Implementation Information: None.
   -------------------------------------------------------------------
   procedure Clear_All_Indicators
   --# global out Mode_PortJ;
   --#        out Result_PortK;
   --#        out Result_PortK_Stored;
   --# derives Mode_PortJ,
   --#         Result_PortK,
   --#         Result_PortK_Stored from ;
   is
   begin
      Clear_All_Mode_Indicators;
      Clear_All_Result_Indicators;
   end Clear_All_Indicators;

end Indicator;
