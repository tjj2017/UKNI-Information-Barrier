----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Toolbox.Maths
--  Stored Filename: $Id: toolbox-maths.ads 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Created By: D Curtis
--  <description>
--               This package contains subprograms to perform the basic
--               mathematic calculations required by IB
--  </description>
----------------------------------------------------------------------

with Mod_Types;

use type Mod_Types.Unsigned_8,
    Mod_Types.Unsigned_64;

--# inherit Mod_Types,
--#         Toolbox;

package Toolbox.Maths is
   -------------------------------------------------------------------
   --  Constants
   -------------------------------------------------------------------
   --  The maximum value for the exponential calculation input
   --  For the IB we are only interested in negative values for the exp function
   MAX_EXPONENT : constant := 0;

   --  The minumum value for the exponential calculation input
   --  For proof purposes, the exponent cannot be the entire long integer range
   --  The following value has been chosen to allow the range needed for all
   --  calculations required by the IB: this is primarily limited by the position
   --  of the 642 peak.
   MIN_EXPONENT : constant := -11000000;

   -------------------------------------------------------------------
   --  Types
   -------------------------------------------------------------------
   --  The viable range for the exponential function input
   subtype Exponential_Input_Type is Long_Integer range MIN_EXPONENT .. MAX_EXPONENT;

   --  The output range for the exponential function output
   subtype Exponential_Output_Type is Mod_Types.Unsigned_16 range 0 .. Toolbox.MULT;

   -------------------------------------------------------------------
   --  Subprograms
   -------------------------------------------------------------------

   -------------------------------------------------------------------
   --  <name> Square_Root </name>
   --  <description> Calculate the square root of the input
   --  </description>
   --  <input name="X">
   --     The number to take the square root of
   --  </input>
   --  <returns>
   --     The square root of X
   --  </returns>
   -------------------------------------------------------------------
   function Square_Root (X : in Mod_Types.Unsigned_16) return Mod_Types.Unsigned_8;

   -------------------------------------------------------------------
   --  <name> Exp </name>
   --  <description> Calculate the Exponential of the input
   --  </description>
   --  <input name="Exponent">
   --     The number to take the exponential of
   --  </input>
   --  <returns>
   --     e^Exponent
   --  </returns>
   -------------------------------------------------------------------
   function Exp (Exponent : in Exponential_Input_Type) return Exponential_Output_Type;

private
   -------------------------------------------------------------------
   --  Constants
   -------------------------------------------------------------------
   --  In order to get the required accuracy for the exponential, an additional *8 is
   --  required on top of the normal multiplier
   INTERNAL_MULT : constant := 8;

   --  The required size of the look up table used to calculate the exponential
   LUT_SIZE      : constant := 20;

   -------------------------------------------------------------------
   --  Types
   -------------------------------------------------------------------

   --  Look up table definition for the exponential function
   --  The smallest possible value is determined by the sum of the power column of the look up table
   subtype Internal_Exp_Type is Long_Integer range
     -2097151 .. 0;

   --  Extended type to hold internal calculation of the exponential calculation before
   --  it is divided back down to give output.
   subtype Exponential_Type is Mod_Types.Unsigned_32 range 0 .. INTERNAL_MULT * Toolbox.MULT;

   --  types for determining the structure of the lookup table to calculate the exponential
   type Look_Up_Table_Format_Type is
      record
         Power2 : Internal_Exp_Type;
         Exponential : Exponential_Type;
      end record;

   subtype LUT_Size_Type is Mod_Types.Unsigned_8 range 0 .. LUT_SIZE - 1;

   type Look_Up_Table_Type is array (LUT_Size_Type) of Look_Up_Table_Format_Type;

   NEG_LUT : constant Look_Up_Table_Type := Look_Up_Table_Type'(
                  Look_Up_Table_Format_Type'(Power2 => -1048576, Exponential => 52),
                  Look_Up_Table_Format_Type'(Power2 => -524288,  Exponential => 2406),
                  Look_Up_Table_Format_Type'(Power2 => -262144,  Exponential => 17744),
                  Look_Up_Table_Format_Type'(Power2 => -131072,  Exponential => 48222),
                  Look_Up_Table_Format_Type'(Power2 => -65536,   Exponential => 79501),
                  Look_Up_Table_Format_Type'(Power2 => -32768,   Exponential => 102080),
                  Look_Up_Table_Format_Type'(Power2 => -16384,   Exponential => 115672),
                  Look_Up_Table_Format_Type'(Power2 => -8192,    Exponential => 123132),
                  Look_Up_Table_Format_Type'(Power2 => -4096,    Exponential => 127040),
                  Look_Up_Table_Format_Type'(Power2 => -2048,    Exponential => 129040),
                  Look_Up_Table_Format_Type'(Power2 => -1024,    Exponential => 130052),
                  Look_Up_Table_Format_Type'(Power2 => -512,     Exponential => 130561),
                  Look_Up_Table_Format_Type'(Power2 => -256,     Exponential => 130817),
                  Look_Up_Table_Format_Type'(Power2 => -128,     Exponential => 130945),
                  Look_Up_Table_Format_Type'(Power2 => -64,      Exponential => 131008),
                  Look_Up_Table_Format_Type'(Power2 => -32,      Exponential => 131041),
                  Look_Up_Table_Format_Type'(Power2 => -16,      Exponential => 131055),
                  Look_Up_Table_Format_Type'(Power2 => -8,       Exponential => 131063),
                  Look_Up_Table_Format_Type'(Power2 => -4,       Exponential => 131068),
                  Look_Up_Table_Format_Type'(Power2 => -2,       Exponential => 131071));

end Toolbox.Maths;
