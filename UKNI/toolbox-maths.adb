----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Toolbox.Maths
--  Stored Filename: $Id: toolbox-maths.adb 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Created By: D Curtis
--  Description: This package contains subprograms to perform the basic
--               mathematic calculations required by IB
----------------------------------------------------------------------

package body Toolbox.Maths is

   -------------------------------------------------------------------
   --  Name       : Square_Root
   --  Implementation Information: Round-Up implementation of a square root.
   -------------------------------------------------------------------
   function Square_Root
     (X : in Mod_Types.Unsigned_16)
      return Mod_Types.Unsigned_8
   is
      --  constituent parts to used to calculate the square root
      --  Both parts start low and are increased until square is greater
      --  than the passed in number
      Square     : Mod_Types.Unsigned_16 := 1;
      Difference : Mod_Types.Unsigned_16 := 1;

      --  The resultant square root
      Root       : Mod_Types.Unsigned_16 := 0;
   begin
      while Square <= X
      loop
         Square := Square + Difference;
         Difference := Difference + 2;
         Root := Root + 1;
      end loop;

      --  This is defensive code as every U16 above 65025 rounds up to 256
      if Root >= Mod_Types.Unsigned_16 (Mod_Types.Unsigned_8'Last) then
         Root := Mod_Types.Unsigned_16 (Mod_Types.Unsigned_8'Last);
      end if;

      return Mod_Types.Unsigned_8 (Root);
   end Square_Root;

   -------------------------------------------------------------------
   --  Name       : Exp
   --  Implementation Information: This implementation is based on the principle that
   --                                  e^(X+Y) = e^X * e^Y
   --                              Based on this, an iterative approach can be made to deconvolve
   --                              e^X to its consituent parts.
   -------------------------------------------------------------------
   function Exp (Exponent : in Exponential_Input_Type)
                 return Exponential_Output_Type
   is

      --  Val is the element of e^Exp which is getting decremented as the
      --  exponential converges to zero
      Val    : Internal_Exp_Type;

      --  Output is combined output of all the constieunt parts of e^X
      Output : Exponential_Type := Toolbox.MULT * INTERNAL_MULT;
   begin
      --  If the input exponent is too small then the answer is 0 within the
      --  given precision of this algorithm
      if Exponent > -16 * Toolbox.MULT then
         Val := Exponent * INTERNAL_MULT;

         for N in LUT_Size_Type loop
            --# assert NEG_LUT(N).Power2 >= Internal_Exp_Type'First and
            --#        NEG_LUT(N).Power2 <= Internal_Exp_Type'Last and
            --#        NEG_LUT(N).Exponential >= Exponential_Type'First and
            --#        NEG_LUT(N).Exponential <= Exponential_Type'Last;
            if Val <= NEG_LUT (N).Power2 then
               Val := Val - NEG_LUT (N).Power2;
               Output := Exponential_Type
                 ((Mod_Types.Unsigned_64 (Output) *
                    Mod_Types.Unsigned_64 (NEG_LUT (N).Exponential)) /
                  (Toolbox.MULT * INTERNAL_MULT));
            end if;
         end loop;

      else
         Output := 0;
      end if;
      return Exponential_Output_Type (Output / INTERNAL_MULT);
   end Exp;

end Toolbox.Maths;
