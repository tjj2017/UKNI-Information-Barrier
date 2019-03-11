----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Toolbox.Peak_Net_Area
--  Stored Filename: $Id: toolbox-peak_net_area.adb 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Created By: D Curtis
--  Description: This package contains subprograms to analyse regions of intereset
--               with respect to background and area
----------------------------------------------------------------------

with Mod_Types,
     Usart1;

package body Toolbox.Peak_Net_Area
is
   -------------------------------------------------------------------
   --  Subprograms
   -------------------------------------------------------------------

   -------------------------------------------------------------------
   --  Name       : ROI_Area
   --  Implementation Information: None.
   -------------------------------------------------------------------
   function ROI_Area (First_Channel : in Channel_Types.Data_Channel_Number;
                      Last_Channel  : in Channel_Types.Data_Channel_Number;
                      ROI           : in Region_Of_Interest.Region_Of_Interest_Type)
                      return Mod_Types.Unsigned_32

   is
      --  Internal representation of the Area under the curve
      Area : Mod_Types.Unsigned_32 := 0;
   begin
      for I in Channel_Types.Data_Channel_Number range First_Channel .. Last_Channel
      loop
         Area := Area + Mod_Types.Unsigned_32 (ROI (I));
         --# assert Last_Channel = Last_Channel% and
         --#        ROI in Region_Of_Interest.Region_Of_Interest_Type and
         --#         Area <= Mod_Types.Unsigned_32((Long_Integer(I - First_Channel + 1)*
         --#            Long_Integer(Mod_Types.Unsigned_16'last)));
      end loop;

      return Area;
   end ROI_Area;

   -------------------------------------------------------------------
   --  Name       : Interpolate_Background
   --  Implementation Information: Not a true function, as engineering
   --                              debug calls are made which change the
   --                              register state.
   -------------------------------------------------------------------
   function Interpolate_Background
     (Peak_ROI_Locations : in Region_Of_Interest.Peak_ROI_Locations_Type;
      Peak_ROI           : in Region_Of_Interest.Region_Of_Interest_Type)
      return Mod_Types.Unsigned_32

   is
      --  Function works out interpolated background based on y = m * x + c
      --  The following variables correspond to the two peaks used for this
      --  calculation
      X1                 : Channel_Types.Data_Channel_Number;
      X2                 : Channel_Types.Data_Channel_Number;
      Y1                 : Mod_Types.Unsigned_32;
      Y2                 : Mod_Types.Unsigned_32;
      Delta_Y            : Long_Integer;
      Delta_X            : Long_Integer;
      M                  : Long_Integer;
      C                  : Long_Long_Integer;

      --  Temporary variable to calculate the counts per channel
      Temp               : Long_Long_Integer;

      --  The background counts per channel
      Counts_Per_Channel : Mod_Types.Unsigned_32;
   begin
      --  X Coordinates are the centre channels of the background regions
      X1 := (Peak_ROI_Locations.Background1_LL + Peak_ROI_Locations.Background1_UL) / 2;
      X2 := (Peak_ROI_Locations.Background2_LL + Peak_ROI_Locations.Background2_UL) / 2;

      --  y coordinates are the mean counts per channel in the background regions
      --  numerator multiplied by 16384 to reduce rounding errors
      Y1 := ((ROI_Area (First_Channel => Peak_ROI_Locations.Background1_LL,
                        Last_Channel  => Peak_ROI_Locations.Background1_UL,
                        ROI           => Peak_ROI)) * Toolbox.MULT) / (Mod_Types.Unsigned_32
                                           (Peak_ROI_Locations.Background1_UL -
                                            Peak_ROI_Locations.Background1_LL) + 1);

      Y2 := ((ROI_Area (First_Channel => Peak_ROI_Locations.Background2_LL,
                        Last_Channel  => Peak_ROI_Locations.Background2_UL,
                        ROI           => Peak_ROI)) * Toolbox.MULT) / (Mod_Types.Unsigned_32
                                            (Peak_ROI_Locations.Background2_UL -
                                             Peak_ROI_Locations.Background2_LL) + 1);

      --# check Peak_ROI_Locations.Background1_UL - Peak_ROI_Locations.Background1_LL >
      --#                                             Channel_Types.Data_Channel_Number'first and
      --#       Peak_ROI_Locations.Background2_UL - Peak_ROI_Locations.Background2_LL >
      --#                                             Channel_Types.Data_Channel_Number'first and
      --#       Peak_ROI_Locations.Background1_UL - Peak_ROI_Locations.Background1_LL <=
      --#                                             Channel_Types.Data_Channel_Number'last and
      --#       Peak_ROI_Locations.Background2_UL - Peak_ROI_Locations.Background2_LL <=
      --#                                             Channel_Types.Data_Channel_Number'last;

      --  m is calculated as Delta Y / Delta X
      --  Integer conversion required as result may be negative
      Delta_Y := (Long_Integer (Y2) - Long_Integer (Y1));
      Delta_X := (Long_Integer (X2) - Long_Integer (X1));

      if Delta_X = 0 then
         Delta_X := 1;
      end if;

      M := Delta_Y / Delta_X;

      --  c = y - m * x
      C := Long_Long_Integer (Y2) - Long_Long_Integer (M) * Long_Long_Integer (X2);
      --  division by 16384 to reverse previous multiplication (to avoid rounding errors)

      Temp := (Long_Long_Integer (M) *
                 Long_Long_Integer (Peak_ROI_Locations.Ideal_Centre_Channel) + C) / Toolbox.MULT;

      --  negative counts doesn't make sense
      if Temp < 0 then
         Counts_Per_Channel := 0;
      else
         Counts_Per_Channel := Mod_Types.Unsigned_32 (Temp);
      end if;

      Usart1.Send_String ("Counts per channel :");
      Usart1.Send_Message_32 (Counts_Per_Channel);
      Usart1.Send_Message_New_Line;

      return Counts_Per_Channel;
   end Interpolate_Background;

   procedure Dump_Peak_Area_Data (Channels_In_Peak      : in Mod_Types.Unsigned_16;
                                  Background            : in Mod_Types.Unsigned_32;
                                  Equivalent_Background : in Mod_Types.Unsigned_32;
                                  Gross_Area            : in Mod_Types.Unsigned_32;
                                  Net_Area              : in Mod_Types.Unsigned_32)
   is
   begin

      Usart1.Send_String (Item => "Peak Area Data Calcs");
      Usart1.Send_Message_New_Line;

      Usart1.Send_String (Item => "Channels_In_Peak:");
      Usart1.Send_Message_16 (Channels_In_Peak);
      Usart1.Send_Message_New_Line;

      Usart1.Send_String ("Background :");
      Usart1.Send_Message_32 (Background);
      Usart1.Send_Message_New_Line;

      Usart1.Send_String ("Equiv. Background :");
      Usart1.Send_Message_32 (Equivalent_Background);
      Usart1.Send_Message_New_Line;

      Usart1.Send_String ("Gross_Area :");
      Usart1.Send_Message_32 (Gross_Area);
      Usart1.Send_Message_New_Line;

      Usart1.Send_String ("Net_Area :");
      Usart1.Send_Message_32 (Net_Area);
      Usart1.Send_Message_New_Line;
   end Dump_Peak_Area_Data;

   -------------------------------------------------------------------
   --  Name       : Peak_Area_Data
   --  Implementation Information: Contains engineering use print statements.
   -------------------------------------------------------------------
   procedure Peak_Area_Data (Peak_ROI_Locations    : in Region_Of_Interest.Peak_ROI_Locations_Type;
                             Peak_ROI              : in Region_Of_Interest.Region_Of_Interest_Type;
                             Equivalent_Background : out Mod_Types.Unsigned_32;
                             Gross_Area            : out Mod_Types.Unsigned_32;
                             Net_Area              : out Mod_Types.Unsigned_32)

   is
      --  The number of channels in the peak within the region of interest
      Channels_In_Peak       : Mod_Types.Unsigned_16;

      --  The background in counts per channel
      Background             : Mod_Types.Unsigned_32;
   begin

      --  Calculate the number of channels in the peak
      Channels_In_Peak := (Peak_ROI_Locations.Peak_UL - Peak_ROI_Locations.Peak_LL) + 1;

      --  Calculate the background per channel
      Background := Interpolate_Background (Peak_ROI_Locations => Peak_ROI_Locations,
                                            Peak_ROI           => Peak_ROI);

      --  Calculate the equivalent background
      Equivalent_Background := (Background * Mod_Types.Unsigned_32 (Channels_In_Peak));

      --  Calculate the gross area of the ROI
      Gross_Area := ROI_Area (First_Channel => Peak_ROI_Locations.Peak_LL,
                              Last_Channel  => Peak_ROI_Locations.Peak_UL,
                              ROI           => Peak_ROI);

      --  Calculate the net area of the ROI
      if Gross_Area > Equivalent_Background then
         Net_Area := Gross_Area - Equivalent_Background;
      else
         Net_Area := 0; -- negative peak area does not make sense
      end if;

      Dump_Peak_Area_Data (Channels_In_Peak      => Channels_In_Peak,
                           Background            => Background,
                           Equivalent_Background => Equivalent_Background,
                           Gross_Area            => Gross_Area,
                           Net_Area              => Net_Area);
   end Peak_Area_Data;

   -------------------------------------------------------------------
   --  Name       : Calculate_Peak_Net_Area
   --  Implementation Information: None.
   -------------------------------------------------------------------
   function Calculate_Peak_Net_Area
     (Peak_ROI_Locations   : in Region_Of_Interest.Peak_ROI_Locations_Type;
      Peak_ROI             : in Region_Of_Interest.Region_Of_Interest_Type)
      return Mod_Types.Unsigned_32
   is
      --  Unused output variables from constituent call
      Equivalent_Background        : Mod_Types.Unsigned_32;
      Gross_Area                   : Mod_Types.Unsigned_32;
      Net_Area                     : Mod_Types.Unsigned_32;
   begin
      --# accept F, 10, Gross_Area, "Variable unused";
      --# accept F, 10, Equivalent_Background, "Variable unused";
      --# accept F, 33, Gross_Area, "Variable unused";
      --# accept F, 33, Equivalent_Background, "Variable unused";
      Peak_Area_Data (Peak_ROI_Locations    => Peak_ROI_Locations,
                      Peak_ROI              => Peak_ROI,
                      Equivalent_Background => Equivalent_Background,
                      Gross_Area            => Gross_Area,
                      Net_Area              => Net_Area);
      return Net_Area;
   end Calculate_Peak_Net_Area;

   -------------------------------------------------------------------
   --  Name       : Calculate_Background
   --  Implementation Information: Not a true function, as engineering
   --                              debug calls are made which change the
   --                              register state.
   -------------------------------------------------------------------
   function Calculate_Background (First_Channel : in Channel_Types.Data_Channel_Number;
                                  Last_Channel  : in Channel_Types.Data_Channel_Number;
                                  ROI           : in Region_Of_Interest.Region_Of_Interest_Type)
                                  return Toolbox.Extended_Channel_Size
   is
      --  Gross area of the region of interest
      Gross_Area : Mod_Types.Unsigned_32;
   begin
      Gross_Area := ROI_Area (First_Channel => First_Channel,
                              Last_Channel  => Last_Channel,
                              ROI           => ROI);
      return Toolbox.Extended_Channel_Size'((Gross_Area * Toolbox.MULT) /
                                      Mod_Types.Unsigned_32 ((Last_Channel - First_Channel) + 1));
   end Calculate_Background;

end Toolbox.Peak_Net_Area;
