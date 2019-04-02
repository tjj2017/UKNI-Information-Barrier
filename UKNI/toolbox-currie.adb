----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Toolbox.Currie
--  Stored Filename: $Id: Toolbox-Currie.adb 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Created By: D Curtis
--  Description:  This package contains subprograms to calculate the Currie Tests
----------------------------------------------------------------------

with Mod_Types,
     Toolbox.Maths,
     Toolbox.Peak_Net_Area,
     Toolbox.Peak_Search,
     Usart1;

use type Mod_Types.Unsigned_64;

package body Toolbox.Currie is

   -------------------------------------------------------------------
   --  Name       : Calculate_Background_Variance
   --  Implementation Information: None.
   -------------------------------------------------------------------
   function Calculate_Background_Variance (Upper_Channel_Centre : in Mod_Types.Unsigned_16;
                                           Lower_Channel_Centre : in Mod_Types.Unsigned_16;
                                           Width_Of_Peak        : in Channel_Types.Data_Channel_Number;
                                           BG_Centre_Difference : in Channel_Types.Data_Channel_Number;
                                           Background_UL        : in Channel_Types.Data_Channel_Number;
                                           Background_LL        : in Channel_Types.Data_Channel_Number;
                                           Search_Array         : in Region_Of_Interest.Region_Of_Interest_Type)
                                              return Mod_Types.Unsigned_16
   is
      BG_Width            : Channel_Types.Data_Channel_Number;

      BG_Area             : Mod_Types.Unsigned_32;
      BG_Variance         : Mod_Types.Unsigned_32;

      Background_Variance : Mod_Types.Unsigned_16;
   begin

      --  Calculate the width and area of the background region
      BG_Width  := (Background_UL - Background_LL) + 1;

      BG_Area := Peak_Net_Area.ROI_Area (First_Channel => Background_LL,
                                         Last_Channel  => Background_UL,
                                         ROI           => Search_Array);
      --# check BG_Area <= 4128705;

      --  Calculate the variance as
      --    __                                           __2
      --   | Upper - Lower Channel Centre    Width_Of_Peak |
      --     ----------------------------  * ------------- |   * BG_Area
      --   | BG_Centre_Difference            BG_Width      |
      --   |__                                           __|
      BG_Variance := (Mod_Types.Unsigned_32 (Upper_Channel_Centre - Lower_Channel_Centre) *
                        Toolbox.MULT) / Mod_Types.Unsigned_32 (BG_Centre_Difference);

      BG_Variance := ((BG_Variance * Mod_Types.Unsigned_32 (Width_Of_Peak))
                      / Mod_Types.Unsigned_32 (BG_Width));

      BG_Variance := BG_Variance * BG_Variance;

      BG_Variance := Mod_Types.Unsigned_32 ((Mod_Types.Unsigned_64 (BG_Variance) *
                                              Mod_Types.Unsigned_64 (BG_Area)) /
                                              Mod_Types.Unsigned_64 (Toolbox.MULT * Toolbox.MULT));

      --  Ensure that the result maintains in type
      if BG_Variance <= Mod_Types.Unsigned_32 (Mod_Types.Unsigned_16'Last) then
         Background_Variance := Mod_Types.Unsigned_16 (BG_Variance);
      else
         Background_Variance := Mod_Types.Unsigned_16'Last;
      end if;
      return Background_Variance;
   end Calculate_Background_Variance;

   -------------------------------------------------------------------
   --  Name       : Critical_Limit
   --  Implementation Information: Not a true function, as engineering
   --                              debug calls are made which change the
   --                              register state.
   -------------------------------------------------------------------
   function Critical_Limit
     (Confidence         : in Mod_Types.Unsigned_16;
      Peak_ROI_Locations : in Region_Of_Interest.Peak_ROI_Locations_Type;
      Peak_ROI           : in Region_Of_Interest.Region_Of_Interest_Type)
      return Boolean
   is

      --  The centre locations of the peak and the background regions
      Peak_Centre               : Mod_Types.Unsigned_16;
      BG1_Centre                : Mod_Types.Unsigned_16;
      BG2_Centre                : Mod_Types.Unsigned_16;

      --  The width of the peak and of the ROI
      Peak_Width                : Channel_Types.Data_Channel_Number;
      ROI_Width                 : Channel_Types.Data_Channel_Number;

      --  Variables for holding the variance due to he background
      Upper_Background_Variance : Mod_Types.Unsigned_16;
      Lower_Background_Variance : Mod_Types.Unsigned_16;
      Total_Background_Variance : Mod_Types.Unsigned_16 :=  Mod_Types.Unsigned_16'Last;

      --  The net area of the ROI
      Net_Area                  : Mod_Types.Unsigned_32;

      --  Variable to hold the square root
      SQRT_Term                 : Mod_Types.Unsigned_8;

      --  The Currie Critical Limit
      Lc                        : Mod_Types.Unsigned_16;

   begin

      ----------------------------------------------------------------------
      --  The Currie Critical Limit is defined as
      --        ____________________________________________________________
      --       /  __               __2         __               __2
      --  K * /  | (CA  - CB1)   nA  |        | (CB2  - CA)   nA  |
      --     /     ----------  * ---   * B1 +   ----------  * ---   * B2
      --    /    | (CB2 - CB1)   nB1 |        | (CB2 - CB1)   nB2 |
      --  \/     |__               __|        |__               __|
      --
      --  Where K is the confidence factor
      --        CA is the centroid channel of the peak (region A)
      --        CBx is the centroid channel of background region x
      --        nA is the number of channels in region A
      --        nBx is the number of channels in background region x
      --        Bx is the background in region x
      --
      --  The demoninator is always larger than the numberator, so the top
      --  needs to be multiplied up so as not to loose accuracy
      ----------------------------------------------------------------------

      Peak_Centre := Peak_Search.Search_For_Peak (Search_Array   => Peak_ROI,
                                                  Upper_Location => Peak_ROI_Locations.Peak_UL,
                                                  Lower_Location => Peak_ROI_Locations.Peak_LL);
      BG1_Centre  := Peak_ROI_Locations.Background1_LL +
        (Peak_ROI_Locations.Background1_UL - Peak_ROI_Locations.Background1_LL) / 2;
      BG2_Centre  := Peak_ROI_Locations.Background2_LL +
        (Peak_ROI_Locations.Background2_UL - Peak_ROI_Locations.Background2_LL) / 2;

      if BG1_Centre < Peak_Centre and Peak_Centre < BG2_Centre then
         Peak_Width := (Peak_ROI_Locations.Peak_UL - Peak_ROI_Locations.Peak_LL) + 1;

         ROI_Width := BG2_Centre - BG1_Centre;

         --  Calculate the variance in the background due to the following term
         --    __               __2
         --   | (CB2 -  CA)   nA  |
         --     ----------  * ---   * B2
         --   | (CB2 - CB1)   nB2 |
         --   |__               __|
         Upper_Background_Variance := Calculate_Background_Variance
           (Upper_Channel_Centre => BG2_Centre,
            Lower_Channel_Centre => Peak_Centre,
            BG_Centre_Difference => ROI_Width,
            Width_Of_Peak        => Peak_Width,
            Background_UL        => Peak_ROI_Locations.Background2_UL,
            Background_LL        => Peak_ROI_Locations.Background2_LL,
            Search_Array         => Peak_ROI);

         --  Calculate the variance in the background due to the following term
         --    __               __2
         --   | (CA  - CB1)   nA  |
         --     ----------  * ---   * B1
         --   | (CB2 - CB1)   nB1 |
         --   |__               __|

         Lower_Background_Variance := Calculate_Background_Variance
           (Upper_Channel_Centre => Peak_Centre,
            Lower_Channel_Centre => BG1_Centre,
            BG_Centre_Difference => ROI_Width,
            Width_Of_Peak        => Peak_Width,
            Background_UL        => Peak_ROI_Locations.Background1_UL,
            Background_LL        => Peak_ROI_Locations.Background1_LL,
            Search_Array         => Peak_ROI);

         --  Add the upper and lower background variances
         if Mod_Types.Unsigned_32 (Upper_Background_Variance) +
           Mod_Types.Unsigned_32 (Lower_Background_Variance) <=
           Mod_Types.Unsigned_32 (Mod_Types.Unsigned_16'Last) then
            Total_Background_Variance := Upper_Background_Variance + Lower_Background_Variance;
         end if;

         --  and take the square root
         SQRT_Term := Maths.Square_Root (X => Total_Background_Variance);

         Lc := Mod_Types.Unsigned_16 ((Mod_Types.Unsigned_32 (Confidence) *
                                      (Mod_Types.Unsigned_32 (SQRT_Term)))/1000);
      else
         Lc := Mod_Types.Unsigned_16'Last;
      end if;

      --  Display the total background
      Usart1.Send_String ("Background Variance: ");
      Usart1.Send_Message_16 (Total_Background_Variance);
      Usart1.Send_Message_New_Line;

      --  Calculate the net area
      Net_Area := Peak_Net_Area.Calculate_Peak_Net_Area (Peak_ROI_Locations => Peak_ROI_Locations,
                                                         Peak_ROI           => Peak_ROI);

      Usart1.Send_String (Item => "Currie CL: ");
      Usart1.Send_Message_16 (Data => Lc);
      Usart1.Send_Message_New_Line;
      return (Net_Area >= Mod_Types.Unsigned_32 (Lc)) and Lc /= Mod_Types.Unsigned_16'Last;
   end Critical_Limit;

end Toolbox.Currie;
