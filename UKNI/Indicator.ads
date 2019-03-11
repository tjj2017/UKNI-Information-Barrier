----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Indicator
--  Stored Filename: $Id: Indicator.ads 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Created By: D Curtis
--  <description>
--               This package provides types and accessor functions to
--               illuminate and extinguish the indicators
--  </description>
----------------------------------------------------------------------

--# inherit Mod_Types,
--#         Registers;

package Indicator
--# own     Result;
--#     out Mode;
--# initializes Result;
is

   -------------------------------------------------------------------
   --  Types
   -------------------------------------------------------------------

   --  enumeration type naming all the indicators
   --  used for constant declaration
   type Indicator_Type is (
      CALIBRATION_MODE,
      MEASUREMENT_MODE,
      CALIBRATION_VERIFY_MODE,
      CALIBRATION_PASS,
      CALIBRATION_FAIL,
      MEASUREMENT_PRESENT,
      MEASUREMENT_NOT_PROVEN,
      CALIBRATION_VERIFY_PASS,
      CALIBRATION_VERIFY_FAIL);

   --  subtype expressing the indicators used to indicate a pass or not proven result
   subtype Result_Indicator_Type is Indicator_Type range CALIBRATION_PASS .. CALIBRATION_VERIFY_FAIL;

   --  subtype expressing the indicators used to indicate which mode has been selected
   subtype Mode_Indicator_Type is Indicator_Type range CALIBRATION_MODE .. CALIBRATION_VERIFY_MODE;

   -------------------------------------------------------------------
   --  Subprograms
   -------------------------------------------------------------------

   -------------------------------------------------------------------
   --  <name> Set_Result_Indicator</name>
   --  <description>
   --               Illuminate the passed in result indicator
   --  </description>
   --  <input name="Indicator_ID">
   --             Which result indicator is to be illuminated
   --  </input>
   --  <output name="None">
   --  </output>
   -------------------------------------------------------------------
   procedure Set_Result_Indicator (Indicator_ID : in Result_Indicator_Type);
   --# global in out Result;
   --# derives Result from *,
   --#                     Indicator_ID;
   pragma Inline (Set_Result_Indicator);

   -------------------------------------------------------------------
   --  <name> Clear_Result_Indicator</name>
   --  <description>
   --               Extinguish the passed in result indicator
   --  </description>
   --  <input name="Indicator_ID">
   --             Which result indicator is to be extinguished
   --  </input>
   --  <output name="None">
   --  </output>
   -------------------------------------------------------------------
   procedure Clear_Result_Indicator (Indicator_ID : in Result_Indicator_Type);
   --# global in out Result;
   --# derives Result from *,
   --#                     Indicator_ID;
   pragma Inline (Clear_Result_Indicator);

   -------------------------------------------------------------------
   --  <name> Clear_All_Result_Indicators</name>
   --  <description>
   --               Extinguish all result indicators
   --  </description>
   --  <input name="None">
   --  </input>
   --  <output name="None">
   --  </output>
   -------------------------------------------------------------------
   procedure Clear_All_Result_Indicators;
   --# global in out Result;
   --# derives Result from *;
   pragma Inline (Clear_All_Result_Indicators);

   -------------------------------------------------------------------
   --  <name> Set_All_Result_Indicators</name>
   --  <description>
   --               Illuminate all result indicators
   --  </description>
   --  <input name="None">
   --  </input>
   --  <output name="None">
   --  </output>
   -------------------------------------------------------------------
   procedure Set_All_Result_Indicators;
   --# global in out Result;
   --# derives Result from *;
   pragma Inline (Set_All_Result_Indicators);

   -------------------------------------------------------------------
   --  <name> Clear_All_Indicators</name>
   --  <description>
   --               Extinguish all indicators
   --  </description>
   --  <input name="None">
   --  </input>
   --  <output name="None">
   --  </output>
   -------------------------------------------------------------------
   procedure Clear_All_Indicators;
   --# global in out Result;
   --#           out Mode;
   --# derives Mode   from  &
   --#         Result from *;
   pragma Inline (Clear_All_Indicators);

   -------------------------------------------------------------------
   --  <name> Set_Current_Mode_Indicator</name>
   --  <description>
   --               Illuminate the passed in mode indicator
   --  </description>
   --  <input name="Indicator_ID">
   --             Which mode indicator is to be illuminated
   --  </input>
   --  <output name="None">
   --  </output>
   -------------------------------------------------------------------
   procedure Set_Current_Mode_Indicator (Indicator_ID : in Mode_Indicator_Type);
   --# global out Mode;
   --# derives Mode from Indicator_ID;
   pragma Inline (Set_Current_Mode_Indicator);

   -------------------------------------------------------------------
   --  <name> Set_All_Mode_Indicators</name>
   --  <description>
   --               Illuminate all the mode indicators
   --  </description>
   --  <input name="None">
   --  </input>
   --  <output name="None">
   --  </output>
   -------------------------------------------------------------------
   procedure Set_All_Mode_Indicators;
   --# global out Mode;
   --# derives Mode from ;
   pragma Inline (Set_All_Mode_Indicators);

   -------------------------------------------------------------------
   --  <name> Clear_All_Mode_Indicators</name>
   --  <description>
   --               Extinguish all the mode indicators
   --  </description>
   --  <input name="None">
   --  </input>
   --  <output name="None">
   --  </output>
   -------------------------------------------------------------------
   procedure Clear_All_Mode_Indicators;
   --# global out Mode;
   --# derives Mode from ;
   pragma Inline (Clear_All_Mode_Indicators);

end Indicator;
