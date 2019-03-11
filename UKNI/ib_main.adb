----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: ib_main
--  Stored Filename: --  $Id: ib_main.adb 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Date Created: 15/11/13
--  Description: Main subprogramme for use when testing subprogrammes
--               within the windows environment
--  Implementation Information: Note nested subprogram bodies in
--                             separate files
----------------------------------------------------------------------
with Ada.Text_IO,
     Calibration,
     Calibration_Peak,
     Measurement,
     Measurement_Peaks,
     Measurement_Peaks.Curve_Fit,
     Mod_Types,
     Region_Of_Interest,
--     Toolbox.Maths,
     Toolbox.Peak_Search,
     Toolbox.Peak_Net_Area,
     Toolbox;

use type Mod_Types.Unsigned_16,
    Mod_Types.Unsigned_32,
    Mod_Types.Unsigned_64;

procedure ib_main
--  test package therefor no annotation here!
is
   Source_CSV : constant String := "C:\IB_Working\Windows\Source_Data\AML194_1.csv";
--     Source_CSV : constant String := "C:\IB_Working\Windows\Source_Data\AML194_2.csv";
--     Source_CSV : constant String := "C:\IB_Working\Windows\Source_Data\AML194_3.csv";
--     Source_CSV : constant String := "C:\IB_Working\Windows\Source_Data\AML194_4.csv";
--     Source_CSV : constant String := "C:\IB_Working\Windows\Source_Data\AML194_5.csv";
--     Source_CSV : constant String := "C:\IB_Working\Windows\Source_Data\AML194_6.csv";
--     Source_CSV : constant String := "C:\IB_Working\Windows\Source_Data\AML20x_1.csv";
--     Source_CSV : constant String := "C:\IB_Working\Windows\Source_Data\AML20x_13.csv";
--     Source_CSV : constant String := "C:\IB_Working\Windows\Source_Data\AML20x_2.csv";
--     Source_CSV : constant String := "C:\IB_Working\Windows\Source_Data\AML20x_3.csv";
--     Source_CSV : constant String := "C:\IB_Working\Windows\Source_Data\AML20x_5.csv";
--     Source_CSV : constant String := "C:\IB_Working\Windows\Source_Data\AML334_1.csv";
--     Source_CSV : constant String := "C:\IB_Working\Windows\Source_Data\AML334_2.csv";
--     Source_CSV : constant String := "C:\IB_Working\Windows\Source_Data\AML334_3.csv";
--     Source_CSV : constant String := "C:\IB_Working\Windows\Source_Data\AML334_4.csv";
--     Source_CSV : constant String := "C:\IB_Working\Windows\Source_Data\AML337_1.csv";
--     Source_CSV : constant String := "C:\IB_Working\Windows\Source_Data\AML337_2.csv";
--     Source_CSV : constant String := "C:\IB_Working\Windows\Source_Data\AML337_3.csv";
--     Source_CSV : constant String := "C:\IB_Working\Windows\Source_Data\AML337_4.csv";
--     Source_CSV : constant String := "C:\IB_Working\Windows\Source_Data\AML337_5.csv";
--     Source_CSV : constant String := "C:\IB_Working\Windows\Source_Data\AML337_6.csv";

   package Mod16_IO is new Ada.Text_IO.Modular_IO (Mod_Types.Unsigned_16);
   package Mod32_IO is new Ada.Text_IO.Modular_IO (Mod_Types.Unsigned_32);
   package Ex_Channel_IO is new Ada.Text_IO.Modular_IO (Measurement_Peaks.Extended_Channel_Type);
   package Int_Channel_IO is new Ada.Text_IO.Integer_IO (Measurement_Peaks.Iso_Difference_Type);

   Source_File : Ada.Text_IO.File_Type;

   subtype ROI_Size is Mod_Types.Unsigned_16 range 1 .. 99;

   Search_Array : Region_Of_Interest.Region_Of_Interest_Type (1 .. 11);
   Search_Array_240 : Region_Of_Interest.Region_Of_Interest_Type (1 .. 30);

   ROI : Region_Of_Interest.Region_Of_Interest_Type (1 .. 99);

   ISO_ROI : Region_Of_Interest.Region_Of_Interest_Type (1621 .. 1720);
   Centroid_662 : Measurement_Peaks.Extended_Channel_Type;
   Diff_Cnt_662 : Measurement_Peaks.Iso_Difference_Type;

   Centroid_645_Due_To_662 : Measurement_Peaks.Extended_Channel_Type;
   Centroid_642_Due_To_662 : Measurement_Peaks.Extended_Channel_Type;

   Offset : Calibration_Peak.Cal_Offset_Type;

   Passed : Boolean;

   Background : Mod_Types.Unsigned_32;

   --  Initialise background per channel at 101
   --  This value must be greater than 100 in order to avoid negative background
   Background_Per_Channel_645 : Mod_Types.Unsigned_32 := 101 * Toolbox.MULT;
   Background_Per_Channel_642 : Mod_Types.Unsigned_32 := 101 * Toolbox.MULT;

   Height_662 : Region_Of_Interest.Peak_Height_Type;
   Height_645 : Region_Of_Interest.Peak_Height_Type;
   Height_642 : Region_Of_Interest.Peak_Height_Type;

   Curve_Fitted_662 : Boolean;
   Curve_Fitted_645 : Boolean;
   Curve_Fitted_642 : Boolean;
   Successful_642 : Boolean;

   Guess_240 : Measurement_Peaks.ROI_640_Type;

   Peak_662_Lo : Mod_Types.Unsigned_16;
   Peak_645_Lo : Mod_Types.Unsigned_16;
   Peak_642_Lo : Mod_Types.Unsigned_16;

   Ratio : Mod_Types.Unsigned_32;

   Cal_Successful : Boolean;
   Is_Present : Boolean;
begin
   Ada.Text_IO.Open (File => Source_File,
                     Mode => Ada.Text_IO.In_File,
                     Name => Source_CSV,
                     Form => "");

   for I in ROI_Size loop
      Mod16_IO.Get (File => Source_File,
                    Item => ROI (I),
                    Width => 0);
   end loop;

   Search_Array := ROI (70 .. 80);

   Calibration.Calculate_Calibration_Parameters (Cal_Offset => Offset,
                                                Is_Successful => Cal_Successful);

   Measurement_Peaks.Set_ROI_Peak (Offset => Offset);

   Toolbox.Peak_Search.Find_Centroid (Search_Array   => Search_Array,
                                      Location       => Measurement_Peaks.Peak_662_Am241,
                                      Channel_Offset => Measurement_Peaks.ISO_662_OFFSET,
                                      Centroid       => Centroid_662,
                                      Difference     => Diff_Cnt_662,
                                      Is_Successful  => Passed);

   Ada.Text_IO.Put ("662 Centroid: ");
   Ex_Channel_IO.Put (Centroid_662);
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put ("Difference: ");
   Int_Channel_IO.Put (Diff_Cnt_662);
   Ada.Text_IO.New_Line;

   Background := Toolbox.Peak_Net_Area.Calculate_Background (First_Channel => 86,
                                                             Last_Channel  => 91,
                                                             ROI           => ROI (80 .. 99));

   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put ("Background: ");
   Mod32_IO.Put (Background);
   Ada.Text_IO.New_Line;
   Ada.Text_IO.New_Line;

   Peak_662_Lo := Mod_Types.Unsigned_16 (Measurement_Peaks.Curve_Fit.Get_Start_Channel
                                         (Centroid_662) / Toolbox.MULT);

   Search_Array := ROI (Peak_662_Lo .. (Peak_662_Lo + Toolbox.PEAK_EVAL_WIDTH));

   Measurement_Peaks.Curve_Fit.Fit_Curve_FWHM (Search_Array    => Search_Array,
                                               Centroid        => Centroid_662,
                                               Background      => Background,
                                               Height          => Height_662,
                                               Good_Fit        => Curve_Fitted_662);

   Centroid_645_Due_To_662 := Measurement_Peaks.Extended_Channel_Type
     (Long_Long_Integer (Diff_Cnt_662) +
      (Long_Long_Integer (Measurement_Peaks.Get_ROI_Peak_Channel (Peak => Measurement_Peaks.Peak_645_Pu239)) -
           Long_Long_Integer (Measurement_Peaks.EXTENDED_ISO_ROI_OFFSET)));

   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put ("645 Centroid: ");
   Ex_Channel_IO.Put (Centroid_645_Due_To_662);
   Ada.Text_IO.New_Line;
   Ada.Text_IO.New_Line;

   Peak_645_Lo := Mod_Types.Unsigned_16 (Measurement_Peaks.Curve_Fit.Get_Start_Channel
                                         (Centroid_645_Due_To_662) / Toolbox.MULT);
   Search_Array := ROI (Peak_645_Lo .. (Peak_645_Lo + Toolbox.PEAK_EVAL_WIDTH));
--     Search_Array := ROI (28 .. 38);

   Measurement_Peaks.Curve_Fit.Fit_Curve_Background (Search_Array    => Search_Array,
                                                     Centroid        => Centroid_645_Due_To_662,
                                                     Background      => Background_Per_Channel_645,
                                                     Height          => Height_645,
                                                     Good_Fit        => Curve_Fitted_645);
   Ada.Text_IO.New_Line;

   Search_Array_240 := ROI (1 .. 30);

   Measurement_Peaks.Set_642_Peaks (Search_Array  => Search_Array_240,
                                    Height_662    => Height_662,
                                    Height_645    => Height_645,
                                    Difference    => Diff_Cnt_662,
                                    Guess_240     => Guess_240,
                                    Centroid      => Centroid_642_Due_To_662,
                                    Is_Successful => Successful_642);
   Ada.Text_IO.New_Line;

   if Successful_642 then

      Peak_642_Lo := Mod_Types.Unsigned_16 (Measurement_Peaks.Curve_Fit.Get_Start_Channel
                                            (Centroid_642_Due_To_662) / Toolbox.MULT);

      for I in Mod_Types.Unsigned_16 range Peak_642_Lo ..  ((Peak_642_Lo + Toolbox.PEAK_EVAL_WIDTH)) loop
         Search_Array ((I + 1) - Peak_642_Lo) := Mod_Types.Unsigned_16 (Guess_240 (I) / Toolbox.MULT);
      end loop;

      Measurement_Peaks.Curve_Fit.Fit_Curve_Background (Search_Array => Search_Array,
                                                        Centroid     => Centroid_642_Due_To_662,
                                                        Background   => Background_Per_Channel_642,
                                                        Height       => Height_642,
                                                        Good_Fit     => Curve_Fitted_642);
   else
      Curve_Fitted_642 := False;
   end if;

   if Curve_Fitted_662 and Curve_Fitted_645 and Curve_Fitted_642 then
      Ratio := Measurement_Peaks.Calculate_Ratio (Pu240_Height => Height_642,
                                                  Pu239_Height => Height_645);
   else
      Ratio := 0;
   end if;

   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put ("The Pu240:Pu239 ratio is: ");
   Mod32_IO.Put (Ratio);
   Ada.Text_IO.New_Line;

   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put ("MEASUREMENT PROCEDURE");
   Ada.Text_IO.New_Line;
   Ada.Text_IO.New_Line;

   for I in ROI_Size loop
      ISO_ROI (I + 1620) := ROI (I);
   end loop;

   Measurement_Peaks.Set_FWHM (FWHM_Value => Measurement_Peaks.FWHM_DEFAULT);

   Measurement.Set_Store (ROI => ISO_ROI);

   Measurement.Perform_Measurement (Is_Present => Is_Present);


end ib_main;
