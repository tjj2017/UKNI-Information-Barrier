----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Toolbox.FWHM
--  Stored Filename: $Id: Toolbox-FWHM.adb 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Created By: D Curtis
--  Description:  This package contains subprograms to calculate the FWHM
----------------------------------------------------------------------

with Channel_Types,
     Mod_Types,
     Toolbox.Peak_Net_Area,
     Toolbox.Peak_Search,
     Usart1;

package body Toolbox.FWHM is

   -------------------------------------------------------------------
   --  Name       : FWHM_Channels
   --  Implementation Information: Not a true function, as engineering
   --                              debug calls are made which change the
   --                              register state.
   -------------------------------------------------------------------
   function FWHM_Channels (Peak_ROI_Locations   : in Region_Of_Interest.Peak_ROI_Locations_Type;
                           Peak_ROI             : in Region_Of_Interest.Region_Of_Interest_Type)
                           return Mod_Types.Unsigned_32
   is
      --  The net peak area of the ROI
      Net_Peak_Area         : Mod_Types.Unsigned_32;

      --  The channel number of the highest count within the ROI
      Peak_Max              : Channel_Types.Data_Channel_Number;

      --  The value of the highest count within the ROI
      Max_Count             : Mod_Types.Unsigned_16;

      --  The equivalent background and the background per channel
      Equivalent_Background : Mod_Types.Unsigned_32;
      Background_Per_Ch     : Mod_Types.Unsigned_16;

      --  The FWHM of the peak within the ROI
      Result                : Mod_Types.Unsigned_32;

      --  The gross area returned by the paek area data command is not required
      Unused2               : Mod_Types.Unsigned_32;

   begin
      --# accept F, 10, Unused2, "Assignment to unused ineffective" &
      --#        F, 33, Unused2, "Assignment to unused ineffective";
      --  Get the equivalent background
      Peak_Net_Area.Peak_Area_Data (Peak_ROI_Locations    => Peak_ROI_Locations,
                                    Peak_ROI              => Peak_ROI,
                                    Equivalent_Background => Equivalent_Background,
                                    Gross_Area            => Unused2,
                                    Net_Area              => Net_Peak_Area);

      --  and calculate the background per channel
      if Equivalent_Background / Mod_Types.Unsigned_32
        ((Peak_ROI_Locations.Peak_UL - Peak_ROI_Locations.Peak_LL) + 1) <=
          Mod_Types.Unsigned_32 (Mod_Types.Unsigned_16'Last) then
         Background_Per_Ch := Mod_Types.Unsigned_16 (Equivalent_Background / Mod_Types.Unsigned_32
                                                     ((Peak_ROI_Locations.Peak_UL - Peak_ROI_Locations.Peak_LL) + 1));
      else
         Background_Per_Ch := Mod_Types.Unsigned_16'Last;
      end if;

      --  locate the peak within the ROI, and extract the maximum height
      Peak_Max := Peak_Search.Search_For_Peak (Search_Array   => Peak_ROI,
                                               Upper_Location => Peak_ROI_Locations.Peak_UL,
                                               Lower_Location => Peak_ROI_Locations.Peak_LL);
      Max_Count := Peak_ROI (Peak_Max);

      --  calculate the FWHM as 0.939 * Net peak area / height of the peak
      if Max_Count > Background_Per_Ch then
         Usart1.Send_String (Item => "Net Height: ");
         Usart1.Send_Message_16 (Max_Count - Background_Per_Ch);
         Usart1.Send_Message_New_Line;

         --  The 939 is a fundamental part of this calculation and will never change.
         Result := ((939 * Net_Peak_Area) / Mod_Types.Unsigned_32 (Max_Count - Background_Per_Ch));
      else
         Result := 0;
      end if;

      Usart1.Send_String (Item => "FWHM Result: ");
      Usart1.Send_Message_32 (Data => Result);
      Usart1.Send_Message_New_Line;
      return Result;
   end FWHM_Channels;
end Toolbox.FWHM;
