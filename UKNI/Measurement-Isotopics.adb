----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Measurement.Isotopics
--  Stored Filename: $Id: Measurement-Isotopics.adb 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Created By: C Marsh
--  Date Created: 15/01/14
--  Description: This private child package handles the isotopic calculations
----------------------------------------------------------------------

with Measurement_Peaks.Curve_Fit,
     Toolbox.Maths,
     Toolbox.Peak_Net_Area,
     Toolbox.Peak_Search,
     Usart1;

package body Measurement.Isotopics is

   -------------------------------------------------------------------
   --  Constants
   -------------------------------------------------------------------

   --  Initialise background per channel for the 645 and 642 peaks at 101
   --  This value must be greater than 100 in order to avoid negative background

   --  The background for the 662 peak is in the following channels
   BACKGROUND_START_CHANNEL : constant :=
     (156 + Measurement_Peaks.ISO_ROI_OFFSET) - 1;
   BACKGROUND_END_CHANNEL   : constant :=
     (165 + Measurement_Peaks.ISO_ROI_OFFSET) - 1;

   --  constant stating the worst case location for a isotopic peak to start
   PEAK_START_MAX : constant := ISO_662_CENTRE_CHANNEL;

   -------------------------------------------------------------------
   --  Types
   -------------------------------------------------------------------
   --  For the 662 estimation, the 662 actual peak and the 645 actual peak, to
   --  minimise memory usage, the same search array can be used as the
   --  evalauted peak widths are the same
   subtype Search_Array_Index_Type is Channel_Types.Data_Channel_Number range
      1 .. (Toolbox.PEAK_EVAL_WIDTH + 1);
   subtype Search_Array_Array_Type is
     Region_Of_Interest.Region_Of_Interest_Type (Search_Array_Index_Type);

   --  The background for the 662 peak is within the are defined in the constants section
   subtype Background_Array_Index_Type is Channel_Types.Data_Channel_Number
   range BACKGROUND_START_CHANNEL .. BACKGROUND_END_CHANNEL;

   subtype Background_Array_Array_Type is Region_Of_Interest.Region_Of_Interest_Type
     (Background_Array_Index_Type);

   -------------------------------------------------------------------
   --  Subprograms
   -------------------------------------------------------------------

   -------------------------------------------------------------------
   --  Name       : Find_662_Centroid
   --  Implementation Information: Contains engineering print statements.
   -------------------------------------------------------------------
   procedure Find_662_Centroid
     (Centroid   : out Channel_Types.Extended_Channel_Type;
      Difference : out Measurement_Peaks.Difference_Type)
   is
      --  Array to hold the ROI to analyse for the 662 peak
      Search_Array        : Search_Array_Array_Type :=
        Search_Array_Array_Type'(others => 0);

      --  Temporary variable variable to calculate difference
      Difference_Long_Int : Long_Integer;

      --  Flag indicating whether Find_Centroid was succcessful
      Peak_Found          : Boolean;
   begin

      --  The loop below is required as SPARK does not support array slices!
      for Each_Channel in Pu662_ROI_Index_Type loop
         Search_Array ((Each_Channel - Pu662_ROI_Index_Type'First) + 1) :=
           Isotopic_ROI (Each_Channel);
      end loop;

      Toolbox.Peak_Search.Find_Centroid (Search_Array   => Search_Array,
                                         Centroid       => Centroid,
                                         Is_Successful => Peak_Found);

      --  Update the value of centroid to reflect its absolute position
      --   (in extended format) and not its relative position
      Centroid := Centroid +
        Channel_Types.Extended_Channel_Type (Pu662_ROI_Index_Type'First - 1) * Toolbox.MULT;

      --  Calculate difference between calculated centroid and estimated
      --  Note: This is measured in IB channels
      Difference_Long_Int := Long_Integer (Centroid)  -
        Long_Integer  (Measurement_Peaks.ROI_Peak (Measurement_Peaks.Peak_662_Am241));

      Usart1.Send_String (Item => "Centroid 662 Location: ");
      Usart1.Send_Message_64 (Data => Mod_Types.Unsigned_64'
                              (Centroid));
      Usart1.Send_Message_New_Line;

      Usart1.Send_String (Item => "Calculated 662 Location: ");
      Usart1.Send_Message_64 (Data => Mod_Types.Unsigned_64'
                              (Measurement_Peaks.ROI_Peak (Measurement_Peaks.Peak_662_Am241)));
      Usart1.Send_Message_New_Line;

      if Difference_Long_Int in Measurement_Peaks.Difference_Type and
        Peak_Found then

         Difference := Measurement_Peaks.Difference_Type'(Difference_Long_Int);

      else

         Centroid := 0;
         Difference := Measurement_Peaks.Difference_Type'Last;
         Usart1.Send_String (Item => "Find Centroid 662 Failed - difference too large");
         Usart1.Send_Message_New_Line;

      end if;

      Usart1.Send_String ("Estimated 662 Difference: ");

      if Difference < 0 then
         Usart1.Send_String ("-");
         Usart1.Send_Message_32 (Data => Mod_Types.Unsigned_32 (-Difference));
      else
         Usart1.Send_Message_32 (Data => Mod_Types.Unsigned_32 (Difference));
      end if;
      Usart1.Send_Message_New_Line;

   end Find_662_Centroid;

   -------------------------------------------------------------------
   --  Name       : Calculate_662_Background
   --  Implementation Information: None.
   -------------------------------------------------------------------
   procedure Calculate_662_Background
     (Background : out Mod_Types.Unsigned_32)
   is
      --  Array to hold the ROI to analyse for the 662 background
      Background_Array : Background_Array_Array_Type :=
         Background_Array_Array_Type'(others => 0);
   begin

      --  The loop below is required as SPARK does not support array slices!
      for Each_Channel in Background_Array_Index_Type loop
         Background_Array (Each_Channel) := Isotopic_ROI (Each_Channel);
      end loop;

      Background :=
         Toolbox.Peak_Net_Area.Calculate_Background (First_Channel => BACKGROUND_START_CHANNEL,
                                                     Last_Channel  => BACKGROUND_END_CHANNEL,
                                                     ROI           => Background_Array);
   end Calculate_662_Background;

   -------------------------------------------------------------------
   --  Name       : Fit_662_Curve
   --  Implementation Information: Fit a guassian curve by varying the FWHM.
   -------------------------------------------------------------------
   procedure Fit_662_Curve
     (Peak_Lo    : in Pu662_ROI_Index_Type;
      Centroid   : in Channel_Types.Extended_Channel_Type;
      Background : in Mod_Types.Unsigned_32;
      Height     : out Region_Of_Interest.Peak_Height_Type;
      Good_Fit   : out Boolean)
   is
      --  Flag to state whether the Isotopic ROI relevant to the 642 is valid
      ROI_Valid    : Boolean                 := True;

      --  ROI to fit the 662 curve to
      Search_Array : Search_Array_Array_Type :=
        Search_Array_Array_Type'(others => 1);

   begin
      --  The loop below is required as SPARK does not support array slices!
      for Each_Channel in ISO_ROI_Index_Type range
            Peak_Lo .. (Peak_Lo + Toolbox.PEAK_EVAL_WIDTH)
      loop

         --  If any of the channels within the ROI are zero, then there is an
         --  issue with the collection of the data
         if Isotopic_ROI (Each_Channel - 1) = 0 or
            Long_Integer (Isotopic_ROI (Each_Channel - 1)) * Toolbox.MULT - Long_Integer (Background) < 0 then
            ROI_Valid := False;
            --# assert Each_Channel >= Peak_Lo and
            --#        Each_Channel <= Peak_Lo + Toolbox.PEAK_EVAL_WIDTH and
            --#        (Each_Channel - Peak_Lo) + 1 >= Search_Array_Array_Type'First and
            --#        (Each_Channel - Peak_Lo) + 1 <= Search_Array_Array_Type'Last and
            --#        Peak_Lo = Peak_Lo% and
            --#        Background = Background% and
            --#        Peak_Lo + Toolbox.PEAK_EVAL_WIDTH <
            --#            ISO_ROI_Index_Type'Last and
            --#        (for all I in Search_Array_Index_Type =>
            --#           (Search_Array(I) /= 0)) and
            --#        not ROI_Valid;
         else
            Search_Array ((Each_Channel - Peak_Lo) + 1)   :=
              Isotopic_ROI (Each_Channel - 1);
            --# assert Each_Channel >= Peak_Lo and
            --#        Each_Channel <= Peak_Lo + Toolbox.PEAK_EVAL_WIDTH and
            --#        (Each_Channel - Peak_Lo) + 1 >= Search_Array_Array_Type'First and
            --#        (Each_Channel - Peak_Lo) + 1 <= Search_Array_Array_Type'Last and
            --#        Peak_Lo = Peak_Lo% and
            --#        Background = Background% and
            --#        Peak_Lo + Toolbox.PEAK_EVAL_WIDTH <
            --#            ISO_ROI_Index_Type'Last and
            --#        ROI_Valid and
            --#        (for all I in Search_Array_Index_Type =>
            --#           (Search_Array(I) /= 0)) and
            --#        (for all J in Channel_Types.Data_Channel_Number range 1
            --#            .. (Each_Channel - Peak_Lo) + 1 => (Mod_Types.Unsigned_32 (Search_Array(J)) *
            --#                       Toolbox.MULT - Background >= 0));
         end if;
         exit when not ROI_Valid;
      end loop;

      if ROI_Valid then
         Measurement_Peaks.Curve_Fit.Fit_Curve_FWHM (Search_Array => Search_Array,
                                                     Centroid     => Centroid,
                                                     Background   => Background,
                                                     Height       => Height,
                                                     Good_Fit     => Good_Fit);
      else
         Height   := 0;
         Good_Fit := False;
      end if;

   end Fit_662_Curve;

   -------------------------------------------------------------------
   --  Name       : Find_645_Centroid
   --  Implementation Information: Contains engineering print statements.
   -------------------------------------------------------------------
   procedure Find_645_Centroid
     (Centroid   : out Channel_Types.Extended_Channel_Type;
      Difference : out Measurement_Peaks.Difference_Type)
   is
      --  Array to hold the ROI to analyse for the 645 peak
      Search_Array        : Search_Array_Array_Type :=
        Search_Array_Array_Type'(others => 0);

      --  Temporary variable variable to calculate difference
      Difference_Long_Int : Long_Integer;

      --  Flag indicating whether Find_Centroid was succcessful
      Peak_Found          : Boolean;
   begin

      --  The loop below is required as SPARK does not support array slices!
      for Each_Channel in Pu645_ROI_Index_Type loop
         Search_Array ((Each_Channel - Pu645_ROI_Index_Type'First) + 1) :=
           Isotopic_ROI (Each_Channel);
      end loop;

      Toolbox.Peak_Search.Find_Centroid (Search_Array   => Search_Array,
                                         Centroid       => Centroid,
                                         Is_Successful => Peak_Found);

      --  Update the value of centroid to reflect its absolute position
      --   (in extended format) and not its relative position
      Centroid := Centroid +
        Channel_Types.Extended_Channel_Type (Pu645_ROI_Index_Type'First - 1) * Toolbox.MULT;

      --  Calculate difference between calculated centroid and estimated
      --  Note: This is measured in IB channels
      Difference_Long_Int := Long_Integer (Centroid)  -
        Long_Integer  (Measurement_Peaks.ROI_Peak (Measurement_Peaks.Peak_645_Pu239));

      Usart1.Send_String (Item => "Centroid 645 Location: ");
      Usart1.Send_Message_64 (Data => Mod_Types.Unsigned_64'
                              (Centroid));
      Usart1.Send_Message_New_Line;

      Usart1.Send_String (Item => "Calculated 645 Location: ");
      Usart1.Send_Message_64 (Data => Mod_Types.Unsigned_64'
                              (Measurement_Peaks.ROI_Peak (Measurement_Peaks.Peak_645_Pu239)));
      Usart1.Send_Message_New_Line;

      if Difference_Long_Int in Measurement_Peaks.Difference_Type and
        Peak_Found then

         Difference := Measurement_Peaks.Difference_Type'(Difference_Long_Int);

      else

         Centroid := 0;
         Difference := Measurement_Peaks.Difference_Type'Last;
         Usart1.Send_String (Item => "Find Centroid 645 Failed - difference too large");
         Usart1.Send_Message_New_Line;

      end if;

      Usart1.Send_String ("Estimated 645 Difference: ");

      if Difference < 0 then
         Usart1.Send_String ("-");
         Usart1.Send_Message_32 (Data => Mod_Types.Unsigned_32 (-Difference));
      else
         Usart1.Send_Message_32 (Data => Mod_Types.Unsigned_32 (Difference));
      end if;
      Usart1.Send_Message_New_Line;

   end Find_645_Centroid;

   -------------------------------------------------------------------
   --  Name       : Fit_645_Curve
   --  Implementation Information: Fit a guassian curve by varying the
   --                              background
   -------------------------------------------------------------------
   procedure Fit_645_Curve
     (Peak_Lo  : in ISO_ROI_Index_Type;
      Centroid : in Channel_Types.Extended_Channel_Type;
      Height   : out Region_Of_Interest.Peak_Height_Type;
      Good_Fit : out Boolean)
   is
      --  Flag to state whether the Isotopic ROI relevant to the 642 is valid
      ROI_Valid    : Boolean                 := True;

      --  ROI to fit the 645 curve to
      Search_Array : Search_Array_Array_Type :=
        Search_Array_Array_Type'(others => 1);

      --  Ununsed variable to hold the background calculated
      Background   : Mod_Types.Unsigned_32;
   begin
      --  Start the backgrond off at 5% of the height of the peak
      Background := Mod_Types.Unsigned_32 (Isotopic_ROI ((Peak_Lo - 1)
                                           + Toolbox.PEAK_EVAL_WIDTH / 2) / 20) * Toolbox.MULT;
      if Background <= Toolbox.MULT then
         Background := Toolbox.MULT;
      end if;
      --# check (for all I in Search_Array_Index_Type =>
      --#           (Search_Array(I) /= 0));
      --  The loop below is required as SPARK does not support array slices!
      for Each_Channel in ISO_ROI_Index_Type range
            Peak_Lo .. (Peak_Lo + Toolbox.PEAK_EVAL_WIDTH)
      loop

         --  If any of the channels within the ROI are zero, then there is an
         --  issue with the collection of the data
         if Isotopic_ROI (Each_Channel - 1) = 0
           or
             Long_Integer (Isotopic_ROI (Each_Channel - 1)) * Toolbox.MULT - Long_Integer (Background) < 0
         then
            ROI_Valid := False;
            --# assert Each_Channel >= Peak_Lo and
            --#        Each_Channel <= Peak_Lo + Toolbox.PEAK_EVAL_WIDTH and
            --#        (Each_Channel - Peak_Lo) + 1 >= Search_Array_Array_Type'First and
            --#        (Each_Channel - Peak_Lo) + 1 <= Search_Array_Array_Type'Last and
            --#        Peak_Lo = Peak_Lo% and
            --#        Peak_Lo + Toolbox.PEAK_EVAL_WIDTH <
            --#            ISO_ROI_Index_Type'Last and
            --#        (for all I in Search_Array_Index_Type =>
            --#           (Search_Array(I) /= 0)) and
            --#        Background >= Toolbox.MULT and
            --#        Background <= Measurement_Peaks.Extended_Height_Type'Last / 20 and
            --#        not ROI_Valid;
         else
            Search_Array ((Each_Channel - Peak_Lo) + 1)   :=
              Isotopic_ROI (Each_Channel - 1);
            --# assert Each_Channel >= Peak_Lo and
            --#        Each_Channel <= Peak_Lo + Toolbox.PEAK_EVAL_WIDTH and
            --#        (Each_Channel - Peak_Lo) + 1 >= Search_Array_Array_Type'First and
            --#        (Each_Channel - Peak_Lo) + 1 <= Search_Array_Array_Type'Last and
            --#        Peak_Lo = Peak_Lo% and
            --#        Peak_Lo + Toolbox.PEAK_EVAL_WIDTH <
            --#           ISO_ROI_Index_Type'Last and
            --#        ROI_Valid and
            --#        Search_Array((Each_Channel - Peak_Lo) + 1) /= 0 and
            --#        Isotopic_ROI (Each_Channel - 1) /= 0 and
            --#        (for all I in Search_Array_Index_Type =>
            --#           (Search_Array(I) /= 0)) and
            --#        (for all J in Channel_Types.Data_Channel_Number range 1
            --#            .. (Each_Channel - Peak_Lo) + 1 => (Mod_Types.Unsigned_32 (Search_Array(J)) *
            --#                       Toolbox.MULT - Background >= 0)) and
            --#        Background <= Measurement_Peaks.Extended_Height_Type'Last / 20 and
            --#        Background >= Toolbox.MULT;
         end if;
         exit when not ROI_Valid;
      end loop;

      if ROI_Valid then

         --# accept F, 10, Background, "Variable unused";
         Measurement_Peaks.Curve_Fit.Fit_Curve_Background (Search_Array => Search_Array,
                                                           Centroid     => Centroid,
                                                           Background   => Background,
                                                           Height       => Height,
                                                           Good_Fit     => Good_Fit);
      else
         Height   := 0;
         Good_Fit := False;
      end if;

   end Fit_645_Curve;

   -------------------------------------------------------------------
   --  Name       : Calculate_637_Location
   --  Implementation Information: Counts engineering use debug statements.
   -------------------------------------------------------------------
   procedure Calculate_637_Location (Difference    : in  Measurement_Peaks.Difference_Type;
                                     Centroid      : out Channel_Types.Extended_Channel_Type;
                                     Is_Successful : out Boolean)
   is
   begin
      if Long_Long_Integer (Difference) +
        (Long_Long_Integer (Measurement_Peaks.ROI_Peak (Measurement_Peaks.Peak_637_Pu239)) -
           Long_Long_Integer (Measurement_Peaks.EXTENDED_ISO_ROI_OFFSET)) >= Pu239_637_Min_Location and then
        Long_Long_Integer (Difference) +
        (Long_Long_Integer (Measurement_Peaks.ROI_Peak (Measurement_Peaks.Peak_637_Pu239)) -
           Long_Long_Integer (Measurement_Peaks.EXTENDED_ISO_ROI_OFFSET)) <= Pu239_637_Max_Location then

         Centroid := Channel_Types.Extended_Channel_Type (Long_Long_Integer (Difference) +
            (Long_Long_Integer (Measurement_Peaks.ROI_Peak (Measurement_Peaks.Peak_637_Pu239)) -
                Long_Long_Integer (Measurement_Peaks.EXTENDED_ISO_ROI_OFFSET)));

         Is_Successful := True;
      else
         Centroid := 0;
         Is_Successful := False;

         Usart1.Send_String
           (Item => "Set_642_Peaks Failed - Centroid_637_Due_To_662 out of bounds");
      end if;
   end Calculate_637_Location;

   -------------------------------------------------------------------
   --  Name       : Calculate_640_Location
   --  Implementation Information: Counts engineering use debug statements.
   -------------------------------------------------------------------
   procedure Calculate_640_Location (Difference    : in  Measurement_Peaks.Difference_Type;
                                     Centroid      : out Channel_Types.Extended_Channel_Type;
                                     Is_Successful : out Boolean)
   is
   begin
      if  Long_Long_Integer (Difference) +
        (Long_Long_Integer (Measurement_Peaks.ROI_Peak (Measurement_Peaks.Peak_640_Pu239)) -
           Long_Long_Integer (Measurement_Peaks.EXTENDED_ISO_ROI_OFFSET)) >= Pu239_640_Min_Location and then
        Long_Long_Integer (Difference) +
        (Long_Long_Integer (Measurement_Peaks.ROI_Peak (Measurement_Peaks.Peak_640_Pu239)) -
           Long_Long_Integer (Measurement_Peaks.EXTENDED_ISO_ROI_OFFSET)) <= Pu239_640_Max_Location then

         Centroid := Channel_Types.Extended_Channel_Type (Long_Long_Integer (Difference) +
            (Long_Long_Integer (Measurement_Peaks.ROI_Peak (Measurement_Peaks.Peak_640_Pu239)) -
                     Long_Long_Integer (Measurement_Peaks.EXTENDED_ISO_ROI_OFFSET)));

         Is_Successful := True;
      else
         Centroid := 0;
         Is_Successful := False;

         Usart1.Send_String
           (Item => "Set_642_Peaks Failed - Centroid_640_Due_To_662 out of bounds");
      end if;
   end Calculate_640_Location;

   -------------------------------------------------------------------
   --  Name       : Calculate_641_Location
   --  Implementation Information: Counts engineering use debug statements.
   -------------------------------------------------------------------
   procedure Calculate_641_Location (Difference    : in  Measurement_Peaks.Difference_Type;
                                     Centroid      : out Channel_Types.Extended_Channel_Type;
                                     Is_Successful : out Boolean)
   is
   begin

      if Long_Long_Integer (Difference) +
        (Long_Long_Integer (Measurement_Peaks.ROI_Peak (Measurement_Peaks.Peak_641_Am241)) -
           Long_Long_Integer (Measurement_Peaks.EXTENDED_ISO_ROI_OFFSET)) >= Am241_641_Min_Location and then
        Long_Long_Integer (Difference) +
        (Long_Long_Integer (Measurement_Peaks.ROI_Peak (Measurement_Peaks.Peak_641_Am241)) -
           Long_Long_Integer (Measurement_Peaks.EXTENDED_ISO_ROI_OFFSET)) <= Am241_641_Max_Location then

         Centroid := Channel_Types.Extended_Channel_Type
           (Long_Long_Integer (Difference) +
            (Long_Long_Integer (Measurement_Peaks.ROI_Peak (Measurement_Peaks.Peak_641_Am241)) -
                 Long_Long_Integer (Measurement_Peaks.EXTENDED_ISO_ROI_OFFSET)));

         Is_Successful := True;
      else
         Centroid := 0;
         Is_Successful := False;

         Usart1.Send_String
           (Item => "Set_642_Peaks Failed - Centroid_641_Due_To_662 out of bounds");
      end if;
   end Calculate_641_Location;

   -------------------------------------------------------------------
   --  Name       : Calculate_642_Location
   --  Implementation Information: Counts engineering use debug statements.
   -------------------------------------------------------------------
   procedure Calculate_642_Location (Difference    : in  Measurement_Peaks.Difference_Type;
                                     Centroid      : out Channel_Types.Extended_Channel_Type;
                                     Is_Successful : out Boolean)
   is
   begin

      if Long_Long_Integer (Difference) +
        (Long_Long_Integer (Measurement_Peaks.ROI_Peak (Measurement_Peaks.Peak_642_Pu240)) -
           Long_Long_Integer (Measurement_Peaks.EXTENDED_ISO_ROI_OFFSET)) >= 0 then

         Centroid := Channel_Types.Extended_Channel_Type
           (Long_Long_Integer (Difference) +
            (Long_Long_Integer (Measurement_Peaks.ROI_Peak (Measurement_Peaks.Peak_642_Pu240)) -
                 Long_Long_Integer (Measurement_Peaks.EXTENDED_ISO_ROI_OFFSET)));

         Is_Successful := True;
      else
         Centroid := 0;
         Is_Successful := False;

         Usart1.Send_String
           (Item => "Set_642_Peaks Failed - Centroid out of bounds");
      end if;
   end Calculate_642_Location;

   function Estimate_640_Peak (Search_Array : in  Region_Of_Interest.Region_Of_Interest_Type;
                               Height_637   : in  Measurement_Peaks.Extended_Height_Type;
                               Height_640   : in  Measurement_Peaks.Extended_Height_Type;
                               Height_641   : in  Measurement_Peaks.Extended_Height_Type;
                               Centroid_637 : in  Channel_Types.Extended_Channel_Type;
                               Centroid_640 : in  Channel_Types.Extended_Channel_Type;
                               Centroid_641 : in  Channel_Types.Extended_Channel_Type)
                               return Measurement_Peaks.ROI_640_Type
   is
      --  Array to hold the ROI to containing the estimate of the Pu240 640 peak
      Guess_240         : Measurement_Peaks.ROI_640_Type := Measurement_Peaks.ROI_640_Type'(others => 0);

      --  The calculated FWHM of the peaks
      FWHM              : Measurement_Peaks.ISO_FWHM_Type;

      --  The guassian constant
      G_Const           : Measurement_Peaks.G_Const_Type;

      --  Temporary variables to hold the height of each peak within the 640 guestimate
      Modelled_Peak_637 : Measurement_Peaks.Extended_Height_Type;
      Modelled_Peak_640 : Measurement_Peaks.Extended_Height_Type;
      Modelled_Peak_641 : Measurement_Peaks.Extended_Height_Type;

   begin
      --  Get the FWHM and calculate the guassian constant
      FWHM := Measurement_Peaks.Get_FWHM;

      --  Set the guassian constant as -1*4*ln(2)) / FWHM ^ 2
      G_Const := Measurement_Peaks.G_Const_Type ((Measurement_Peaks.GG_CONST /
                                                   Long_Long_Integer (FWHM)) / Long_Long_Integer (FWHM));

      --  Model the peaks
      for N in Measurement_Peaks.ROI_640_Size loop

         --# assert Centroid_637 <= Pu239_637_Max_Location and
         --#        Centroid_637 >= Pu239_637_Min_Location and
         --#        Centroid_640 <= Pu239_640_Max_Location and
         --#        Centroid_640 >= Pu239_640_Min_Location and
         --#        Centroid_641 <= Am241_641_Max_Location and
         --#        Centroid_641 >= Am241_641_Min_Location and
         --#        Search_Array'First >= Channel_Types.Data_Channel_Number'First and
         --#        Search_Array'Last <= Channel_Types.Data_Channel_Number'Last and
         --#        Measurement_Peaks.ROI_640_Size'Last + Search_Array'First >= Search_Array'First and
         --#        Measurement_Peaks.ROI_640_Size'Last + Search_Array'First <= Search_Array'Last and
         --#        (N + Search_Array'First) <= Search_Array'Last and
         --#        (N + Search_Array'First) >= Search_Array'First;

         Modelled_Peak_637 := Measurement_Peaks.Extended_Height_Type
           ((Mod_Types.Unsigned_64 (Height_637) *
              Mod_Types.Unsigned_64 (Toolbox.Maths.Exp
                (Exponent => Toolbox.Maths.Exponential_Input_Type ((Long_Long_Integer (G_Const) *
                 (((Long_Long_Integer (N) * Toolbox.MULT) - Long_Long_Integer (Centroid_637)) *
                    (((Long_Long_Integer (N) * Toolbox.MULT) - Long_Long_Integer (Centroid_637))))) /
                 (Toolbox.MULT * Toolbox.MULT)))))/ Toolbox.MULT);

         Modelled_Peak_640 := Measurement_Peaks.Extended_Height_Type
           ((Mod_Types.Unsigned_64 (Height_640) *
              Mod_Types.Unsigned_64 (Toolbox.Maths.Exp
                (Exponent => Toolbox.Maths.Exponential_Input_Type ((Long_Long_Integer (G_Const) *
                 (((Long_Long_Integer (N) * Toolbox.MULT) - Long_Long_Integer (Centroid_640)) *
                    (((Long_Long_Integer (N) * Toolbox.MULT) - Long_Long_Integer (Centroid_640))))) /
                 (Toolbox.MULT * Toolbox.MULT))))) / Toolbox.MULT);

         Modelled_Peak_641 :=  Measurement_Peaks.Extended_Height_Type
           ((Mod_Types.Unsigned_64 (Height_641) *
              Mod_Types.Unsigned_64 (Toolbox.Maths.Exp
                (Exponent => Toolbox.Maths.Exponential_Input_Type ((Long_Long_Integer (G_Const) *
                  (((Long_Long_Integer (N) * Toolbox.MULT) - Long_Long_Integer (Centroid_641)) *
                     (((Long_Long_Integer (N) * Toolbox.MULT) - Long_Long_Integer (Centroid_641))))) /
                 (Toolbox.MULT * Toolbox.MULT)))))/ Toolbox.MULT);

         if  Mod_Types.Unsigned_64 ((Modelled_Peak_637 + Modelled_Peak_640) + Modelled_Peak_641) <
           Mod_Types.Unsigned_64 (Search_Array ((N + Search_Array'First))) * Toolbox.MULT then
            Guess_240 (N) := ((Measurement_Peaks.Extended_Height_Type
                              (Search_Array ((N + Search_Array'First))) * Toolbox.MULT -
                                Modelled_Peak_637) - Modelled_Peak_640) - Modelled_Peak_641;
         else
            Guess_240 (N) := Toolbox.MULT;
         end if;
      end loop;
      return Guess_240;
   end Estimate_640_Peak;

   -------------------------------------------------------------------
   --  Name       : Set_642_Peaks
   --  Implementation Information: Counts engineering use debug statements.
   -------------------------------------------------------------------
   procedure Set_642_Peaks (Search_Array  : in  Region_Of_Interest.Region_Of_Interest_Type;
                            Height_662    : in  Region_Of_Interest.Peak_Height_Type;
                            Height_645    : in  Region_Of_Interest.Peak_Height_Type;
                            Difference    : in  Measurement_Peaks.Difference_Type;
                            Guess_240     : out Measurement_Peaks.ROI_640_Type;
                            Centroid      : out Channel_Types.Extended_Channel_Type;
                            Is_Successful : out Boolean)
   is
      --  The contribution of the 637 peak within the 642 peak
      --  Calculated as the branching ratio of Pu239 @ 637keV / Pu239 @ 645keV * mult
      --                                    = 2.56E-8 / 1.49E-7 * 16384
      CONTRIBUTION_637 : constant := 2815;

      --  The contribution of the 640 peak within the 642 peak
      --  Calculated as the branching ratio of Pu239 @ 640keV / Pu239 @ 645keV * mult
      --                                    = 8.2E-8 / 1.49E-7 * 16384
      CONTRIBUTION_640 : constant := 9017;

      --  The contribution of the 641 peak within the 642 peak
      --  Calculated as the branching ratio of Am241 @ 641keV / Am241 @ 662keV * mult
      --                                    = 7.1E-6 / 3.64E-4 * 16384
      CONTRIBUTION_641 : constant := 320;

      --  The calcalated relative peaks of the consituent parts of the 642 peak
      Height_637 : Measurement_Peaks.Extended_Height_Type;
      Height_640 : Measurement_Peaks.Extended_Height_Type;
      Height_641 : Measurement_Peaks.Extended_Height_Type;

      --  Calculated location of the centroids for the constituent parts of the 642 peak
      Centroid_637_Due_To_645 : Channel_Types.Extended_Channel_Type;
      Centroid_640_Due_To_645 : Channel_Types.Extended_Channel_Type;
      Centroid_641_Due_To_645 : Channel_Types.Extended_Channel_Type;

      --  Flags indicating whether the constituent centroids are in expected locations
      Peak_637_Found : Boolean;
      Peak_640_Found : Boolean;
      Peak_641_Found : Boolean;
      Peak_642_Found : Boolean;

   begin

      --  Intialisation of output array
      Guess_240 := Measurement_Peaks.ROI_640_Type'(others => 0);
      --  Calculate the height of the peaks
      Height_637 := CONTRIBUTION_637 * Mod_Types.Unsigned_32'(Height_645);
      Height_640 := CONTRIBUTION_640 * Mod_Types.Unsigned_32'(Height_645);
      Height_641 := CONTRIBUTION_641 * Mod_Types.Unsigned_32'(Height_662);

      --  Calculate the location of the peak centroids
      --  The 637 peak should be within 10 channels of the theoretical location
      --  associated with 638.837 keV
      Calculate_637_Location (Difference    => Difference,
                              Centroid      => Centroid_637_Due_To_645,
                              Is_Successful => Peak_637_Found);

      Calculate_640_Location (Difference    => Difference,
                              Centroid      => Centroid_640_Due_To_645,
                              Is_Successful => Peak_640_Found);

      Calculate_641_Location (Difference    => Difference,
                              Centroid      => Centroid_641_Due_To_645,
                              Is_Successful => Peak_641_Found);

      Calculate_642_Location (Difference    => Difference,
                              Centroid      => Centroid,
                              Is_Successful => Peak_642_Found);

      Is_Successful := Peak_637_Found and Peak_640_Found and Peak_641_Found and Peak_642_Found;

      if Is_Successful then
            Guess_240 := Estimate_640_Peak (Search_Array => Search_Array,
                                            Height_637   => Height_637,
                                            Height_640   => Height_640,
                                            Height_641   => Height_641,
                                            Centroid_637 => Centroid_637_Due_To_645,
                                            Centroid_640 => Centroid_640_Due_To_645,
                                            Centroid_641 => Centroid_641_Due_To_645);
      end if;

      Usart1.Send_String (Item => "Set_642_Peaks - Centroid Value: ");
      Usart1.Send_Message_64 (Data => Mod_Types.Unsigned_64'(Centroid));
      Usart1.Send_Message_New_Line;

   end Set_642_Peaks;

   -------------------------------------------------------------------
   --  Name       : Deconvolve_642_Triplet
   --  Implementation Information: None
   -------------------------------------------------------------------
   procedure Deconvolve_642_Triplet
     (Height_662_Peak : in Region_Of_Interest.Peak_Height_Type;
      Height_645_Peak : in Region_Of_Interest.Peak_Height_Type;
      Difference      : in Measurement_Peaks.Difference_Type;
      Guess           : out Measurement_Peaks.ROI_640_Type;
      Centroid        : out Channel_Types.Extended_Channel_Type;
      Is_Successful   : out Boolean)
   is

      --  For the 642 peak, a wider search array is required
      subtype Array_240_Index_Type is Channel_Types.Data_Channel_Number range
        ISO_642_LL .. ISO_642_UL;

      subtype Array_240_Array_Type is
        Region_Of_Interest.Region_Of_Interest_Type (Array_240_Index_Type);

      --  ROI containing the 642 triplet to deconvolve
      Search_Array : Array_240_Array_Type :=
         Array_240_Array_Type'(others => 0);

   begin

      for Each_Channel in Array_240_Index_Type loop
         Search_Array (Each_Channel) := Isotopic_ROI (Each_Channel);
      end loop;

      Set_642_Peaks (Search_Array  => Search_Array,
                     Height_662    => Height_662_Peak,
                     Height_645    => Height_645_Peak,
                     Difference    => Difference,
                     Guess_240     => Guess,
                     Centroid      => Centroid,
                     Is_Successful => Is_Successful);
   end Deconvolve_642_Triplet;

   -------------------------------------------------------------------
   --  Name       : Fit_642_Curve
   --  Implementation Information: Fit a guassian curve by varying the
   --                              background
   -------------------------------------------------------------------
   procedure Fit_642_Curve
     (Peak_Lo  : in Measurement_Peaks.ROI_640_Size;
      Centroid : in Channel_Types.Extended_Channel_Type;
      ROI      : in Measurement_Peaks.ROI_640_Type;
      Height   : out Region_Of_Interest.Peak_Height_Type;
      Good_Fit : out Boolean)
   is
      --  Flag to state whether the Isotopic ROI relevant to the 642 is valid
      ROI_Valid    : Boolean                 := True;

      --  ROI to fit the curve to
      Search_Array : Search_Array_Array_Type :=
        Search_Array_Array_Type'(others => 1);

      --  Ununsed variable to hold the background calculated
      Background   : Mod_Types.Unsigned_32;

   begin
      --  Start the background off at 25% of the height of the peak
      Background := ROI ((Peak_Lo - 1) + Toolbox.PEAK_EVAL_WIDTH / 2) / 4;
      if Background <= Toolbox.MULT then
         Background := Toolbox.MULT;
      end if;

      for Each_Channel in Mod_Types.Unsigned_16 range
            Peak_Lo .. (Peak_Lo + Toolbox.PEAK_EVAL_WIDTH)
      loop

         --  If any channel in the guestimate distribution is too high or zero
         --  then we don't have a valid distribution
         if ROI (Each_Channel - 1) / Toolbox.MULT = 0 or
            ROI (Each_Channel - 1) / Toolbox.MULT >=
            Region_Of_Interest.Peak_Height_Type (Mod_Types.Unsigned_16'Last)
         then

            ROI_Valid := False;
            --# assert Each_Channel >= Peak_Lo and
            --#        Each_Channel <= Peak_Lo + Toolbox.PEAK_EVAL_WIDTH and
            --#        (Each_Channel - Peak_Lo) + 1 >= Search_Array_Array_Type'First and
            --#        (Each_Channel - Peak_Lo) + 1 <= Search_Array_Array_Type'Last and
            --#        Peak_Lo = Peak_Lo% and
            --#        Peak_Lo + Toolbox.PEAK_EVAL_WIDTH <
            --#            ISO_ROI_Index_Type'Last and
            --#        (for all I in Search_Array_Index_Type =>
            --#           (Search_Array(I) /= 0)) and
            --#        Background >= Toolbox.MULT and
            --#        Background <= Measurement_Peaks.Extended_Height_Type'Last / 4 and
            --#        not ROI_Valid;
         else
            Search_Array ((Each_Channel - Peak_Lo) + 1) :=
                 Mod_Types.Unsigned_16 (ROI (Each_Channel - 1) / Toolbox.MULT);

            --# assert Each_Channel >= Peak_Lo and
            --#        Each_Channel <= Peak_Lo + Toolbox.PEAK_EVAL_WIDTH and
            --#        (Each_Channel - Peak_Lo) + 1 >= Search_Array_Array_Type'First and
            --#        (Each_Channel - Peak_Lo) + 1 <= Search_Array_Array_Type'Last and
            --#        Each_Channel >= 0 and
            --#        Each_Channel <= 54 and
            --#        Peak_Lo = Peak_Lo% and
            --#        Peak_Lo + Toolbox.PEAK_EVAL_WIDTH <
            --#             Measurement_Peaks.ROI_640_Type'Last and
            --#        ROI (Each_Channel - 1) / Toolbox.MULT /= 0 and
            --#        ROI_Valid and
            --#        (for all I in Channel_Types.Data_Channel_Number range Search_Array_Array_Type'First
            --#            .. Search_Array_Array_Type'Last => (Search_Array(I) /= 0)) and
            --#        Background >= Toolbox.MULT and
            --#        Background <= Measurement_Peaks.Extended_Height_Type'Last / 4;
         end if;
         exit when not ROI_Valid;
      end loop;

      if ROI_Valid then
         --# accept F, 10, Background, "Variable unused";
         Measurement_Peaks.Curve_Fit.Fit_Curve_Background
           (Search_Array => Search_Array,
            Centroid     => Centroid,
            Background   => Background,
            Height       => Height,
            Good_Fit     => Good_Fit);
      else
         Height   := 0;
         Good_Fit := False;
      end if;

   end Fit_642_Curve;

   -------------------------------------------------------------------
   --  Name       : Analyse_662_Peak
   --  Implementation Information: None.
   -------------------------------------------------------------------
   procedure Analyse_662_Peak (Location_Difference : out Measurement_Peaks.Difference_Type;
                               Height              : out Region_Of_Interest.Peak_Height_Type;
                               Curve_Fitted        : out Boolean)
   is
      --  Location of the 662 centroid
      Centroid_662   : Channel_Types.Extended_Channel_Type;

      --  The calculated background for the 662 peak
      Background_662 : Mod_Types.Unsigned_32;

      --  Start of the 662, 645 and 642 regions of interest as calculated from
      --  the centroid location of the 662 peak
      Peak_662_Lo    : Channel_Types.Data_Channel_Number;
   begin
      --  Set default values
      Height := 0;
      Curve_Fitted := False;

      --  Find the centroid of the 662 peak
      Find_662_Centroid (Centroid   => Centroid_662,
                         Difference => Location_Difference);

      --  if a peak cannot be found, there is no point in continuing with
      --  the calcalations
      if Centroid_662 < Channel_Types.Extended_Channel_Type (ISO_662_UL) * Toolbox.MULT and then
        Centroid_662 > Channel_Types.Extended_Channel_Type (ISO_662_LL) * Toolbox.MULT then

         --  Calculate the start channel for the 662 peak
         Peak_662_Lo := (Channel_Types.Data_Channel_Number (
                         Measurement_Peaks.Curve_Fit.Get_Start_Channel (Centroid => Centroid_662) /
                           Toolbox.MULT)) + 1;

         --  Ensure that Peak_662_Lo is in a valid location
         if Peak_662_Lo >= PEAK_START_MAX then
            Peak_662_Lo := 0;
         end if;

         --  Calculate the background
         Calculate_662_Background (Background => Background_662);

         --  Fit a curve to the 662 peak
         if Peak_662_Lo in Pu662_ROI_Index_Type and then
           Background_662 >= Toolbox.MULT and then
           Background_662 <= Mod_Types.Unsigned_32
             (Mod_Types.Unsigned_16'Last) * Toolbox.MULT
         then

            Fit_662_Curve (Peak_Lo    => Peak_662_Lo,
                           Centroid   => Centroid_662,
                           Background => Background_662,
                           Height     => Height,
                           Good_Fit   => Curve_Fitted);
         end if;

      end if;
   end Analyse_662_Peak;

   -------------------------------------------------------------------
   --  Name       : Analyse_645_Peak
   --  Implementation Information: Includes engineering use print statements.
   -------------------------------------------------------------------
   procedure Analyse_645_Peak (Difference_662 : in  Measurement_Peaks.Difference_Type;
                               Difference_645 : out  Measurement_Peaks.Difference_Type;
                               Height         : out Region_Of_Interest.Peak_Height_Type;
                               Curve_Fitted   : out Boolean)
   is
      --  Location of the 645 centroid
      Centroid_645   : Channel_Types.Extended_Channel_Type;

      --  Channel number where the 645 peak starts
      Peak_645_Start : Channel_Types.Data_Channel_Number;
   begin
      --  Set default output conditions
      Curve_Fitted := False;
      Height := 0;
      Peak_645_Start := 0;

      --  Find the centroid of the 645 peak
      Find_645_Centroid (Centroid   => Centroid_645,
                         Difference => Difference_645);

      --  Check that the differences are within 0.5 of a channel of each other
      if abs (abs (Difference_645) - abs (Difference_662)) <= Toolbox.MULT / 2 then

         --  Check that the estimated location of the 645 centroid is in a valid position
         if Centroid_645 < Channel_Types.Extended_Channel_Type (ISO_645_UL) * Toolbox.MULT and then
           Centroid_645 > Channel_Types.Extended_Channel_Type (ISO_645_LL) * Toolbox.MULT then

            Peak_645_Start := Mod_Types.Unsigned_16
              (Measurement_Peaks.Curve_Fit.Get_Start_Channel (Centroid => Centroid_645) /
                   Toolbox.MULT) + 1;
         end if;

         --  If the 645 centroid and peak location are in a valid location, the
         --  the procedure has been successful
         if Centroid_645 > Channel_Types.Extended_Channel_Type'First + Toolbox.PEAK_EVAL_GUARD and then
           Centroid_645 < Channel_Types.Extended_Channel_Type'Last - Toolbox.PEAK_EVAL_GUARD and then
           Peak_645_Start in Pu645_ROI_Index_Type then

            Fit_645_Curve (Peak_Lo  => Peak_645_Start,
                           Centroid => Centroid_645,
                           Height   => Height,
                           Good_Fit => Curve_Fitted);

            if Height = 0 then
               Curve_Fitted := False;
            end if;
         end if;
      end if;
   end Analyse_645_Peak;

   -------------------------------------------------------------------
   --  Name       : Analyse_642_Peak
   --  Implementation Information: Includes engineering use print statements.
   -------------------------------------------------------------------
   procedure Analyse_642_Peak (Location_Difference : in  Measurement_Peaks.Difference_Type;
                               Height_662          : in  Region_Of_Interest.Peak_Height_Type;
                               Height_645          : in  Region_Of_Interest.Peak_Height_Type;
                               Height_642          : out Region_Of_Interest.Peak_Height_Type;
                               Curve_Fitted        : out Boolean)
   is

      --  Flag stating whether the 642 deconvolution is successful
      Successful_642 : Boolean;

      --  Estimation of the Pu240 Peak
      Guess_240      : Measurement_Peaks.ROI_640_Type;

      --  Centroid Locations of the 642 peaks
      Centroid       : Channel_Types.Extended_Channel_Type;

      --  Start of the 642 regions of interest as calculated from
      --  the centroid location of the 662 peak
      Peak_642_Lo : Channel_Types.Data_Channel_Number;
   begin
      --  Set default output conditions
      Curve_Fitted := False;
      Height_642 := Region_Of_Interest.Peak_Height_Type'Last;

      --  Deconvolve the 642 triplet to get the Pu240 peak
      Deconvolve_642_Triplet
        (Height_662_Peak => Height_662,
         Height_645_Peak => Height_645,
         Difference      => Location_Difference,
         Guess           => Guess_240,
         Centroid        => Centroid,
         Is_Successful   => Successful_642);

      --  Calculate the height of the 642 Pu240 peak

      --  For the peak to be successfully found, it cannot be too
      --  close to either edge of the ROI
      Successful_642 := Successful_642 and
        Centroid < Channel_Types.Extended_Channel_Type (ISO_642_UL) *
        Toolbox.MULT - Measurement_Peaks.EXTENDED_ISO_ROI_OFFSET and
        Centroid > Channel_Types.Extended_Channel_Type'First +
            Toolbox.PEAK_EVAL_GUARD;

      if Successful_642 then
         --  Calculate where the ROI for the Pu240 peak starts
         Peak_642_Lo := Mod_Types.Unsigned_16
           (Measurement_Peaks.Curve_Fit.Get_Start_Channel
              (Centroid) / Toolbox.MULT) + 1;

         if Peak_642_Lo < ISO_ROI_Index_Type'Last - Measurement_Peaks.ISO_ROI_OFFSET and then
           ((Peak_642_Lo + Measurement_Peaks.ISO_ROI_OFFSET) +
            (Toolbox.PEAK_EVAL_WIDTH + 1)) in Pu642_ROI_Index_Type then
            --  and fit the curve
            Fit_642_Curve (Peak_Lo  => Peak_642_Lo,
                           Centroid => Centroid,
                           ROI      => Guess_240,
                           Height   => Height_642,
                           Good_Fit => Curve_Fitted);
         end if;
      end if;

      Usart1.Send_String (Item => "642 Centroid: ");
      Usart1.Send_Message_64 (Data =>
                                Mod_Types.Unsigned_64'(Centroid));
      Usart1.Send_Message_New_Line;
   end Analyse_642_Peak;

   -------------------------------------------------------------------
   --  Name       : Determine_Isotopic_Ratio
   --  Implementation Information: Includes engineering use print statements.
   -------------------------------------------------------------------
   procedure Determine_Isotopic_Ratio
     (Peaks_Found : out Boolean;
      Ratio       : out Mod_Types.Unsigned_32)
   is

      --  The difference between  the channel where the 662 max is and the calculated
      --  centroid and whether a centroid has been found in the ROI
      Diff_Cnt_662     : Measurement_Peaks.Difference_Type;

      --  The difference between  the channel where the 645 max is and the calculated
      --  centroid and whether a centroid has been found in the ROI
      Diff_Cnt_645     : Measurement_Peaks.Difference_Type;

      --  Calculated heights of the 662, 645 and 642 peaks
      Height_662       : Region_Of_Interest.Peak_Height_Type;
      Height_645       : Region_Of_Interest.Peak_Height_Type;
      Height_642       : Region_Of_Interest.Peak_Height_Type;

      --  Flag stating whether a curve can be fitted to the 662, 645 and 642
      --  peaks
      Curve_Fitted_662 : Boolean;
      Curve_Fitted_645 : Boolean;
      Curve_Fitted_642 : Boolean;

   begin
      --  Set the default output conditions
      Ratio       := Toolbox.MULT;
      Peaks_Found := False;

      --  Analyse the 662 peak
      Analyse_662_Peak (Location_Difference => Diff_Cnt_662,
                        Height              => Height_662,
                        Curve_Fitted        => Curve_Fitted_662);

      if Curve_Fitted_662 then
         --  Analyse the 645 peak
         Analyse_645_Peak (Difference_662 => Diff_Cnt_662,
                           Difference_645 => Diff_Cnt_645,
                           Height         => Height_645,
                           Curve_Fitted   => Curve_Fitted_645);

         if Curve_Fitted_645 then

            Analyse_642_Peak (Location_Difference => Diff_Cnt_645,
                              Height_662          => Height_662,
                              Height_645          => Height_645,
                              Height_642          => Height_642,
                              Curve_Fitted        => Curve_Fitted_642);

            --  Calculate the ratio
            if Curve_Fitted_642 then
               Ratio := Measurement_Peaks.Calculate_Ratio
                 (Pu240_Height => Height_642,
                  Pu239_Height => Height_645);

               Peaks_Found := True;
            else
               Ratio       := Toolbox.MULT;
               Peaks_Found := False;
            end if;
         end if;
      end if;

   end Determine_Isotopic_Ratio;

   -------------------------------------------------------------------
   --  Name       : Clear_Isotopic_Store
   --  Implementation Information: None.
   -------------------------------------------------------------------
   procedure Clear_Isotopic_Store
   is
      --# hide Clear_Isotopic_Store;
   begin
      --  hidden body, as array initialisation done via loop
      --  avoiding expensive memory constant array

      for I in ISO_ROI_Index_Type loop
         Isotopic_ROI (I) := 0;
      end loop;
   end Clear_Isotopic_Store;

   -------------------------------------------------------------------
   --  Name       : Increment_ROI_Element
   --  Implementation Information: None.
   -------------------------------------------------------------------
   procedure Increment_ROI_Element (Index : in ISO_ROI_Index_Type)
   is
   begin

      if Isotopic_ROI (Index) < Mod_Types.Unsigned_16'Last then
         Isotopic_ROI (Index) := Isotopic_ROI (Index) + 1;
      end if;

   end Increment_ROI_Element;

end Measurement.Isotopics;
