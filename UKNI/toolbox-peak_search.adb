----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Toolbox.Peak_Search
--  Stored Filename: $Id: toolbox-peak_search.adb 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Created By: D Curtis
--  Description: This package contains subprograms to find maximums and centroids
--               of the peaks that the IB requires to either identify or are
--               relevant to determine the isotopic ration
----------------------------------------------------------------------
with Mod_Types,
     Toolbox,
     Usart1;

use type Mod_Types.Unsigned_64;

package body Toolbox.Peak_Search is

   -------------------------------------------------------------------
   --  Name       : Search_For_Peak
   --  Implementation Information: None.
   -------------------------------------------------------------------
   function Search_For_Peak (Search_Array   : in Region_Of_Interest.Region_Of_Interest_Type;
                             Upper_Location : in Channel_Types.Data_Channel_Number;
                             Lower_Location : in Channel_Types.Data_Channel_Number)
                             return Channel_Types.Data_Channel_Number

   is
      --  Location of the maxima of the search array
      Highest_Count_Channel : Channel_Types.Data_Channel_Number;
   begin
      Highest_Count_Channel := Lower_Location;

      for I in Channel_Types.Data_Channel_Number range Lower_Location .. Upper_Location loop
         if Search_Array (I) > Search_Array (Highest_Count_Channel) then
            Highest_Count_Channel := I;
            --# check Search_Array(Highest_Count_Channel) = Search_Array(I);
         end if;
         --# assert Highest_Count_Channel <= Upper_Location and
         --#         Highest_Count_Channel >= Lower_Location and
         --#         Upper_Location = Upper_Location% and
         --#         Search_Array(Highest_Count_Channel) >= Search_Array(I) and
         --#         (for all Y in Channel_Types.Data_Channel_Number range
         --#               Highest_Count_Channel .. I =>
         --#                  (Search_Array(Highest_Count_Channel) >= Search_Array(Y))) and
         --#         (for all X in Channel_Types.Data_Channel_Number range
         --#               Lower_Location .. Highest_Count_Channel =>
         --#                  ((Search_Array(Highest_Count_Channel) > Search_Array(X)) or
         --#                   (Search_Array(Highest_Count_Channel) = Search_Array(X) and
         --#                        Highest_Count_Channel = X)));
      end loop;
      return Highest_Count_Channel;
   end Search_For_Peak;

   -------------------------------------------------------------------
   --  Name       : Find_Centroid
   --  Implementation Information: Perform a 5 channel analysis to find the centroid
   --                              The matlab design has an additional input
   --                              parameter containing the start address in the
   --                              search area corresponding to the lhs of the peak
   --                              For the implementation, only the relevant part
   --                              of the peak is passed in so the peak_info_lo
   --                              parameter is not needed
   --                              Includes engineering use print statements.
   -------------------------------------------------------------------
   procedure Find_Centroid (Search_Array   : in  Region_Of_Interest.Region_Of_Interest_Type;
                            Centroid       : out Channel_Types.Extended_Channel_Type;
                            Is_Successful  : out Boolean)
   is
      --  The channel to contain the maximum value from the search array
      Peak_Char_Cnt       : Channel_Types.Data_Channel_Number;

      --  The terms associated with the 5 channel analysis
      MC_Plus_1           : Mod_Types.Unsigned_16;
      MC_Plus_2           : Mod_Types.Unsigned_16;
      MC                  : Mod_Types.Unsigned_16;
      MC_Minus_1          : Mod_Types.Unsigned_16;
      MC_Minus_2          : Mod_Types.Unsigned_16;

      MC_Minus_MC_Plus_2  : Mod_Types.Unsigned_16;
      MC_Minus_MC_Minus_2 : Mod_Types.Unsigned_16;

      Neg2_Term           : Mod_Types.Unsigned_32;
      Pos2_Term           : Mod_Types.Unsigned_32;

      subtype Adjustment_Type is Long_Long_Integer range
        0 - Long_Long_Integer (Mod_Types.Unsigned_32'Last) ..
        2 * Long_Long_Integer (Mod_Types.Unsigned_32'Last);

      Diff                : Adjustment_Type;
      Sum                 : Adjustment_Type;

      --  constant to determine how far from the edges of the region of interest
      --  the peak must be.
      NUM_CHANNELS        : constant := 3;

   begin

      --  Get the integer channel containing the maximum value within the search array
      Peak_Char_Cnt := Search_For_Peak (Search_Array   => Search_Array,
                                        Upper_Location => Search_Array'Last,
                                        Lower_Location => Search_Array'First);
      Usart1.Send_String ("Highest Count Channel In Peak: ");
      Usart1.Send_Message_16 (Data => Peak_Char_Cnt);
      Usart1.Send_Message_New_Line;

      --  set default values for the output
      Is_Successful := False;
      Centroid := Channel_Types.Extended_Channel_Type (Peak_Char_Cnt)  * Toolbox.MULT;

      --  If the Peak channel is too close to the either side of the array, we are looking in the wrong place
      if Peak_Char_Cnt + NUM_CHANNELS <= Search_Array'Last and then
        Peak_Char_Cnt + NUM_CHANNELS <= Channel_Types.Data_Channel_Number'Last and then
        Search_Array'Last <= Channel_Types.Data_Channel_Number'Last and then
        Peak_Char_Cnt - NUM_CHANNELS >= Search_Array'First and then
        Peak_Char_Cnt >= NUM_CHANNELS then

         --  Perform a 5 channel analysis
         --  If centroid = c and counts vector is m, then the following equation is
         --  simply:
         --  c' = c + {m(c+1)*[m(c)-m(c-2)] - m(c-1)*[m(c)-m(c+2)]} /
         --           {m(c+1)*[m(c)-m(c-2)] + m(c-1)*[m(c)-m(c+2)]}

         --  Define the individual terms
         --# Check (Peak_Char_Cnt + 2) in Search_Array'range and
         --#       (Peak_Char_Cnt + 1) in Search_Array'range and
         --#       (Peak_Char_Cnt)     in Search_Array'range and
         --#       (Peak_Char_Cnt - 1) in Search_Array'range and
         --#       (Peak_Char_Cnt - 2) in Search_Array'range;
         MC_Plus_2  := Search_Array (Peak_Char_Cnt + 2);
         MC_Plus_1  := Search_Array (Peak_Char_Cnt + 1);
         MC         := Search_Array (Peak_Char_Cnt);
         MC_Minus_1 := Search_Array (Peak_Char_Cnt - 1);
         MC_Minus_2 := Search_Array (Peak_Char_Cnt - 2);

         --  Define the composite terms
         --# Check MC >= MC_Plus_2  and
         --#       MC >= MC_Plus_1  and
         --#       MC > MC_Minus_1 and
         --#       MC > MC_Minus_2;
         MC_Minus_MC_Plus_2  := MC - MC_Plus_2;
         MC_Minus_MC_Minus_2 := MC - MC_Minus_2;

         --  define the rhs of the demoninator and the numerator
         Neg2_Term := Mod_Types.Unsigned_32 (MC_Plus_1) * Mod_Types.Unsigned_32 (MC_Minus_MC_Minus_2);

         --  define the lhs of the demoninator and the numerator
         Pos2_Term := Mod_Types.Unsigned_32 (MC_Minus_1) * Mod_Types.Unsigned_32 (MC_Minus_MC_Plus_2);

         --  Define the top and bottom of the demoninator and numberator
         Diff := Adjustment_Type (Neg2_Term) - Adjustment_Type (Pos2_Term);
         Sum  := Adjustment_Type (Neg2_Term) + Adjustment_Type (Pos2_Term);

         if Sum /= 0 then

            Centroid := Channel_Types.Extended_Channel_Type
              ((Long_Long_Integer (Peak_Char_Cnt) * Toolbox.MULT +
               ((Long_Long_Integer'(Diff) * Toolbox.MULT) / Long_Long_Integer'(Sum))));

            Is_Successful := True;
            Usart1.Send_String (Item => "Estimate Centroid Passed");
            Usart1.Send_Message_New_Line;
         end if;
      end if;

      Usart1.Send_String ("Centroid Channel: ");
      Usart1.Send_Message_64 (Data => Centroid);
      Usart1.Send_Message_New_Line;

   end Find_Centroid;
end Toolbox.Peak_Search;
