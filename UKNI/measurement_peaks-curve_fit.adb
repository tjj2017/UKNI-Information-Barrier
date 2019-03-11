----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Measurement_Peaks.Curve_Fit
--  Stored Filename: $Id: measurement_peaks-curve_fit.adb 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Created By: C Marsh
--  Date Created: 28/11/13
--  Description: Package container for curve fitting of the isotopic peaks
----------------------------------------------------------------------

with Channel_Types,
     Toolbox.Maths,
     Usart1;

package body Measurement_Peaks.Curve_Fit is

   -------------------------------------------------------------------
   --  Subprograms
   -------------------------------------------------------------------

   -------------------------------------------------------------------
   --  Name       : Get_Start_Channel
   --  Implementation Information: None.
   -------------------------------------------------------------------
   function Get_Start_Channel (Centroid : in Channel_Types.Extended_Channel_Type)
                                  return Channel_Types.Extended_Channel_Type
   is

      --  Temporary variable to calculate the [@*mult] position of
      --  the centroid
      Remainder        : Channel_Types.Extended_Channel_Type;

      --  Integer location of the centroid {@*mult]
      Integer_Centroid : Channel_Types.Extended_Channel_Type;
   begin
      --  Find the closest channel to determine peak centroid and
      --  determine the difference.
      Remainder := Channel_Types.Extended_Channel_Type'(Centroid rem Toolbox.MULT);

      if Remainder > Channel_Types.Extended_Channel_Type (Toolbox.MULT / 2) then
         Integer_Centroid := (Centroid + Toolbox.MULT) - Remainder;
         --# check   Integer_Centroid <= Centroid + Toolbox.MULT and
         --#         Integer_Centroid >= Centroid;
      else
         Integer_Centroid := Centroid - Remainder;
         --# check   Integer_Centroid <= Centroid and
         --#         Integer_Centroid >= Centroid - Toolbox.MULT;
      end if;

      return Integer_Centroid - (Toolbox.PEAK_EVAL_WIDTH / 2) * Toolbox.MULT;
   end Get_Start_Channel;

   -------------------------------------------------------------------
   --  Name       : Get_Max
   --  Implementation Information: None.
   -------------------------------------------------------------------
   function Get_Max (Search : in  Region_Of_Interest.Region_Of_Interest_Type)
                     return Mod_Types.Unsigned_16
   is
      Max_Val : Mod_Types.Unsigned_16;
   begin
      Max_Val := Search (Search'First);
      for I in Channel_Types.Data_Channel_Number range Search'First .. Search'Last loop
         if Search (I) > Max_Val then
            Max_Val := Search (I);
            --# check Max_Val = Search(I);
         end if;
         --# assert for all J in Channel_Types.Data_Channel_Number range
         --#               Search'First .. I => (Search(J) <= Max_Val);
      end loop;
      return Max_Val;
   end Get_Max;
   pragma Inline (Get_Max);

   -------------------------------------------------------------------
   --  Name       : Generate_Guassian
   --  Implementation Information: None.
   -------------------------------------------------------------------
   procedure Generate_Gaussian (Centroid_Location : in  Channel_Types.Extended_Channel_Type;
                                St_Channel        : in  Channel_Types.Extended_Channel_Type;
                                Gaussian_Constant : in  Measurement_Peaks.G_Const_Type;
                                Gaussian_Peak     : out Normalised_Modelled_Peak_Type;
                                Peak_Max          : out Normalized_Height_Type)
   is
   begin
      Gaussian_Peak := Normalised_Modelled_Peak_Type'(others => 0);
      --  The allowable FWHM ranges from 6 .. 9 (@*MULT).
      --  The maximum difference between the integer peak channel and the peak
      --  channel is 0.5
      --  Therefor the lowest point that the max point of the curve can be is
      --  given by exp((-1*4*log(2) / 9^2) * 0.5^2) = c.  0.9915
      --  This equates to 16244 (@*mult)
      Peak_Max     := MODELLED_PEAK_MINIMUM_HEIGHT;

      --  Calculated the theoretical peak using the exp function
      for N in Modelled_Peak_Size_Type loop
         --#  assert Peak_Max >= MODELLED_PEAK_MINIMUM_HEIGHT and
         --#        St_Channel + (Toolbox.PEAK_EVAL_WIDTH / 2) * Toolbox.MULT -
         --#                        (Toolbox.PEAK_EVAL_WIDTH / 2) * Toolbox.MULT > 0 and
         --#        St_Channel + (Toolbox.PEAK_EVAL_WIDTH / 2) * Toolbox.MULT <=
         --#                         Centroid_Location + Toolbox.MULT and
         --#        St_Channel + (Toolbox.PEAK_EVAL_WIDTH / 2) * Toolbox.MULT  >=
         --#                         Centroid_Location - Toolbox.MULT;

         Gaussian_Peak (N) := Toolbox.Maths.Exp
           (Exponent => Toolbox.Maths.Exponential_Input_Type
              ((Long_Long_Integer (Gaussian_Constant) *
               ((Long_Long_Integer (Centroid_Location) -
                        Long_Long_Integer (St_Channel + Channel_Types.Extended_Channel_Type (N)
                      * Toolbox.MULT)) *
                      (Long_Long_Integer (Centroid_Location) -
                           Long_Long_Integer (St_Channel + Channel_Types.Extended_Channel_Type (N)
                         * Toolbox.MULT)))) /
                 (Toolbox.MULT * Toolbox.MULT)));

         if Gaussian_Peak (N) > Peak_Max then
            Peak_Max := Gaussian_Peak (N);
         end if;
      end loop;
   end Generate_Gaussian;

   -------------------------------------------------------------------
   --  Name       : Calculate_Chi
   --  Implementation Information: None.
   -------------------------------------------------------------------
   function Calculate_Chi (Search_Array  : in Region_Of_Interest.Region_Of_Interest_Type;
                           Gaussian_Peak : in Normalised_Modelled_Peak_Type;
                           Peak_Max      : in Region_Of_Interest.Peak_Height_Type;
                           Background    : in Toolbox.Extended_Channel_Size;
                           Array_Start   : in Modelled_Peak_Size_Type;
                           Array_End     : in Modelled_Peak_Size_Type) return Chi2_Array_Type
   is
      --  The variance between the modelled and actual peaks
      subtype Variance_Type is Long_Long_Integer range
        0 - Long_Long_Integer (Expanded_Peak_Type'Last) ..
        Long_Long_Integer (Expanded_Peak_Type'Last);

      --  Temporary variable used in the calculation of the Chi square of each value
      --  of interest within the ROI peak
      Expanded_Peak   : Expanded_Peak_Type;
      Variance  : Variance_Type;

      --  Array to hold the Chi2_arry to calculate chi2 top
      Chi2_Array      : Chi2_Array_Type :=
        Chi2_Array_Type'(others => 0);
   begin

      for I in Modelled_Peak_Size_Type range Array_Start .. Array_End loop
         --# assert Mod_Types.Unsigned_16(I) + Search_Array'First <= Search_Array'Last and
         --#        Mod_Types.Unsigned_16(I) + Search_Array'First >= Search_Array'First and
         --#        Search_Array'Length >= Toolbox.PEAK_EVAL_WIDTH + 1 and
         --#        Array_Start = Array_Start% and
         --#        Array_End = Array_End%;

         Expanded_Peak := Expanded_Peak_Type (Gaussian_Peak (I)) *
           Expanded_Peak_Type (Peak_Max) + Expanded_Peak_Type (Background);

         --  And determine the variance
         Variance := Variance_Type (Expanded_Peak) -
           Variance_Type (Search_Array ((Mod_Types.Unsigned_16 (I)) +
                              Search_Array'First)) * Toolbox.MULT;

         --  The chi-square parameters [O - E]^2/sigma^2]:
         --  Note the guassuan statistics i.e. N= sigma^2 is assumed
         Chi2_Array (I) := Chi2_Type ((
           Long_Long_Integer'(Variance) * Long_Long_Integer'(Variance)) /
           (Long_Long_Integer
              (Search_Array ((Mod_Types.Unsigned_16 (I)) + Search_Array'First)) * Toolbox.MULT));
      end loop;

      return Chi2_Array;
   end Calculate_Chi;

   -------------------------------------------------------------------
   --  Name       : Gaussian_Inc
   --  Implementation Information: Includes engineering use print statements.
   -------------------------------------------------------------------
   procedure Gaussian_Inc
     (Search_Array : in  Region_Of_Interest.Region_Of_Interest_Type;
      Centroid     : in  Channel_Types.Extended_Channel_Type;
      Background   : in  Toolbox.Extended_Channel_Size;
      FWHM         : in  Measurement_Peaks.ISO_FWHM_Type;
      Red_Chi2_Top : out Mod_Types.Unsigned_64;
      Norman       : out Region_Of_Interest.Peak_Height_Type)
   is

      -------------------------------------------------------------------
      --  Variables
      -------------------------------------------------------------------

      --  Start Channel where gaussian curve should start
      Start_Channel    : Channel_Types.Extended_Channel_Type;

      --  The guassian constant
      G_Const           : Measurement_Peaks.G_Const_Type;

      --  Arrays to hold the calculated information
      Normalised_Peak   : Normalised_Modelled_Peak_Type;

      --  Temporary variables to hold maximum values of arrays
      SA_Max            : Mod_Types.Unsigned_16;

      --  Height of the gaussian peak
      Modelled_Max      : Normalized_Height_Type;

      --  Array to hold the elements for the reduced chi squared test
      Chi2_Array        : Chi2_Array_Type;

   ----------------------------------------------------------------  ---
   --  Constants
   -------------------------------------------------------------------
      --  Constants to determine the number of vectors for the chi squared calcalation
      CHI_START         : constant := 9;
      CHI_END           : constant := 15;

      --  The reduced chi square top is calculated with a seperation of 6
      RED_CHI2_TOP_SIZE : constant := CHI_END - CHI_START;

   begin

      Start_Channel := Get_Start_Channel (Centroid => Centroid);

      --  Set the guassian constant as -1*4*log(2) / FWHM ^ 2
      G_Const := Measurement_Peaks.G_Const_Type ((Measurement_Peaks.GG_CONST /
                                                   Long_Long_Integer (FWHM)) / Long_Long_Integer (FWHM));

      --  Calculate the maximum value from within the passed in ROI
      SA_Max := Get_Max (Search => Search_Array);

      Generate_Gaussian (Centroid_Location => Centroid,
                         St_Channel        => Start_Channel,
                         Gaussian_Constant => G_Const,
                         Gaussian_Peak     => Normalised_Peak,
                         Peak_Max          => Modelled_Max);

      --  Determine the normalisation factor
      --  Due to the nature of the calling algorithm, this test is allowed to fail
      if (Mod_Types.Unsigned_32 (SA_Max) * Toolbox.MULT) > Background then
         Norman := Region_Of_Interest.Peak_Height_Type'((Mod_Types.Unsigned_32 (SA_Max) *
                                                          Toolbox.MULT - Background) /
                                                         Mod_Types.Unsigned_32 (Modelled_Max));
      else
         Norman := 0;
      end if;

      Chi2_Array := Calculate_Chi (Search_Array  => Search_Array,
                                   Gaussian_Peak => Normalised_Peak,
                                   Peak_Max      => Norman,
                                   Background    => Background,
                                   Array_Start   => CHI_START,
                                   Array_End     => CHI_END);

      --  Calculate the reduced Chi Squared Top
      if Modelled_Max = MODELLED_PEAK_MINIMUM_HEIGHT then
         --  Mathematically this should not be able to execute
         Usart1.Send_String (Item => "Error: Guassian_Inc - Mathematical inconsistency");
         Usart1.Send_Message_New_Line;
         Red_Chi2_Top := Mod_Types.Unsigned_64'Last;
      else
         Red_Chi2_Top := Mod_Types.Unsigned_64'(((((((Chi2_Array (9) + Chi2_Array (10))
                                                + Chi2_Array (11)) + Chi2_Array (12)) +
                                                  Chi2_Array (13)) + Chi2_Array (14)) +
                                                  Chi2_Array (15)) / RED_CHI2_TOP_SIZE);
      end if;
   end Gaussian_Inc;

   -------------------------------------------------------------------
   --  Name       : Update_Incrementer
   --  Implementation Information: None.
   -------------------------------------------------------------------
   function Update_Incrementer (Old_Chi2     : in Mod_Types.Unsigned_64;
                                Current_Chi2 : in Mod_Types.Unsigned_64;
                                Old_Inc      : in Mod_Types.Unsigned_32)
                                return Mod_Types.Unsigned_32
   is
      New_Inc : Mod_Types.Unsigned_64;
   begin
      if abs (Long_Long_Integer (Current_Chi2) -
                Long_Long_Integer (Old_Chi2)) > Toolbox.MULT then

         --  The design has a *0.9 multiplication on this decrease
         --  To speed up a ratio of 29/32 = 0.90625 has been used
         New_Inc := (Mod_Types.Unsigned_64 (Old_Inc) * 29) / 32;

      else

         New_Inc := Mod_Types.Unsigned_64 (Old_Inc) / 2;

      end if;
      return Mod_Types.Unsigned_32 (New_Inc);
   end Update_Incrementer;

   -------------------------------------------------------------------
   --  Name       : Dump_Curve_Fit_Data
   --  Implementation Information: Includes engineering use print statements.
   -------------------------------------------------------------------
   procedure Dump_Curve_Fit_Data (Curve_Fit_Variable : in String;
                                  Curve_Fitted       : in Boolean;
                                  Peak_Height        : in Region_Of_Interest.Peak_Height_Type;
                                  Red_Chi2_Top       : in Mod_Types.Unsigned_64;
                                  Red_Chi2_Top_Old   : in Mod_Types.Unsigned_64;
                                  Incrementer        : in Mod_Types.Unsigned_32)
   is
   begin
      Usart1.Send_String (Item => "Curve Fit ");
      Usart1.Send_String (Item => Curve_Fit_Variable);
      if Curve_Fitted then
         Usart1.Send_String (Item => " Passed");
      else
         Usart1.Send_String (Item => " Failure");
      end if;
      Usart1.Send_Message_New_Line;
      Usart1.Send_String (Item => "Height: ");
      Usart1.Send_Message_32 (Data => Mod_Types.Unsigned_32'(Peak_Height));
      Usart1.Send_Message_New_Line;
      Usart1.Send_String (Item => "Reduced Chi Squared Top: ");
      Usart1.Send_Message_64 (Data => Red_Chi2_Top);
      Usart1.Send_Message_New_Line;
      Usart1.Send_String (Item => "Reduced Chi Squared Top Old: ");
      Usart1.Send_Message_64 (Data => Red_Chi2_Top_Old);
      Usart1.Send_Message_New_Line;
      Usart1.Send_String (Item => "Incrementer: ");
      Usart1.Send_Message_32 (Data => Incrementer);
      Usart1.Send_Message_New_Line;
   end Dump_Curve_Fit_Data;

   -------------------------------------------------------------------
   --  Name       : Check_Fit
   --  Implementation Information: None.
   -------------------------------------------------------------------
   procedure Check_Fit (Fit_Accuracy       : in     Mod_Types.Unsigned_32;
                        Red_Chi2_Top       : in     Mod_Types.Unsigned_64;
                        Red_Chi2_Top_Old   : in     Mod_Types.Unsigned_64;
                        Peak_Height        : in out Region_Of_Interest.Peak_Height_Type;
                        Curve_Fitted       :    out Boolean)
   is
      --  Maximum value of the reduced chi square top to be a good fit
      MAX_CHI2_TOP : constant := 16 * Toolbox.MULT;
   begin
      if (Red_Chi2_Top < Mod_Types.Unsigned_64 (MAX_CHI2_TOP)) and then
        Red_Chi2_Top_Old < Mod_Types.Unsigned_64'Last / 2 and then
        (abs (Long_Long_Integer (Red_Chi2_Top) -
                Long_Long_Integer (Red_Chi2_Top_Old)) <= Long_Long_Integer (Fit_Accuracy)) then
         Curve_Fitted := True;
      else
         Curve_Fitted := False;
         Peak_Height := 0;
      end if;
   end Check_Fit;

   -------------------------------------------------------------------
   --  Name       : Check_Chi2_Value
   --  Implementation Information: Not a true function, as engineering
   --                              debug calls are made which change the
   --                              register state.
   -------------------------------------------------------------------
   function Check_Chi2_Value (Chi2_Value : in Mod_Types.Unsigned_64) return Boolean
   is
      Value_Valid : Boolean;
   begin
      if Chi2_Value < Mod_Types.Unsigned_64'Last / 2 then
         Value_Valid := True;
      else
         Value_Valid := False;
         Usart1.Send_String (Item => "Error: Curve Fit - Reduced chi top too big");
         Usart1.Send_Message_New_Line;
      end if;
      return Value_Valid;
   end Check_Chi2_Value;

   -------------------------------------------------------------------
   --  Name       : Adjust_FWHM
   --  Implementation Information: Includes engineering use print statements.
   -------------------------------------------------------------------
   procedure Adjust_FWHM (Current_Value : in  Measurement_Peaks.ISO_FWHM_Type;
                          Incrementer   : in  FWHM_Incrementer_Type;
                          New_Value_1   : out Measurement_Peaks.ISO_FWHM_Type;
                          New_Value_2   : out Measurement_Peaks.ISO_FWHM_Type;
                          Fail          : out Boolean)
   is
   begin
      New_Value_1 := Measurement_Peaks.ISO_FWHM_Type'Last;
      New_Value_2 := Measurement_Peaks.ISO_FWHM_Type'Last;
      Fail := False;

      if Mod_Types.Unsigned_32'(Current_Value) <
        Mod_Types.Unsigned_32'(Measurement_Peaks.ISO_FWHM_Type'First) + Incrementer then
         --  FWHM is too narrow (current value - incrementer < Measurement_Peaks.ISO_FWHM_Type'First)
         Usart1.Send_String (Item => "Error: Curve Fit FWHM - FWHM is too narrow");
         Usart1.Send_Message_New_Line;

         Fail := True;

      elsif Mod_Types.Unsigned_32'(Current_Value) >
        Mod_Types.Unsigned_32'(Measurement_Peaks.ISO_FWHM_Type'Last) - Incrementer then
         --  FWHM is too wide (current value + incrementer > Measurement_Peaks.ISO_FWHM_Type'Last
         Usart1.Send_String (Item => "Error: Curve Fit FWHM - FWHM is too wide");
         Usart1.Send_Message_New_Line;

         Fail := True;
      else
         --  Calculate the reduced chi square for values positioned +/-
         --  Inc either side

         --  Vary the FWHM
         New_Value_1 := Measurement_Peaks.ISO_FWHM_Type'(Mod_Types.Unsigned_32'(Current_Value) -
                                                           Mod_Types.Unsigned_32'(Incrementer));
         New_Value_2 := Measurement_Peaks.ISO_FWHM_Type'(Mod_Types.Unsigned_32'(Current_Value) +
                                                           Mod_Types.Unsigned_32'(Incrementer));
      end if;
   end Adjust_FWHM;

   -------------------------------------------------------------------
   --  Name       : Try_Curve_FWHM
   --  Implementation Information: None.
   -------------------------------------------------------------------
   procedure Try_Curve_FWHM (Search_Array       : in     Region_Of_Interest.Region_Of_Interest_Type;
                             Centroid           : in     Channel_Types.Extended_Channel_Type;
                             Background         : in     Toolbox.Extended_Channel_Size;
                             FWHM_In1           : in     Measurement_Peaks.ISO_FWHM_Type;
                             FWHM_In2           : in     Measurement_Peaks.ISO_FWHM_Type;
                             Red_Chi2_Top       : in out Mod_Types.Unsigned_64;
                             Red_Chi2_Top_Old   : in out Mod_Types.Unsigned_64;
                             FWHM_Out           : in out Measurement_Peaks.ISO_FWHM_Type;
                             Peak_Height        :    out Region_Of_Interest.Peak_Height_Type)
   is
      --  Chi square values of previous runs to store and compare against
      Red_Chi2_Top_Old_Old : Mod_Types.Unsigned_64;
      Red_Chi2_Top1        : Mod_Types.Unsigned_64;
      Red_Chi2_Top2        : Mod_Types.Unsigned_64;

      --  Local variables for varying the FWHM to fit the curve
      FWHM_Main            : Measurement_Peaks.ISO_FWHM_Type;

      --  Local variables for storing heights for attempting to fit the curve
      Height1              : Region_Of_Interest.Peak_Height_Type;
      Height2              : Region_Of_Interest.Peak_Height_Type;
      Height_Main          : Region_Of_Interest.Peak_Height_Type;

   begin
      --  Store old values
      Red_Chi2_Top_Old_Old := Red_Chi2_Top_Old;
      Red_Chi2_Top_Old := Red_Chi2_Top;

      Peak_Height := 0;

      --# assert Red_Chi2_Top < Mod_Types.Unsigned_64'Last / 2 and
      --#        Red_Chi2_Top_Old < Mod_Types.Unsigned_64'Last / 2 and
      --#        Red_Chi2_Top_Old_Old < Mod_Types.Unsigned_64'Last / 2;

      Gaussian_Inc (Search_Array => Search_Array,
                    Centroid     => Centroid,
                    Background   => Background,
                    FWHM         => FWHM_In1,
                    Red_Chi2_Top => Red_Chi2_Top1,
                    Norman       => Height1);

      Gaussian_Inc (Search_Array => Search_Array,
                    Centroid     => Centroid,
                    Background   => Background,
                    FWHM         => FWHM_In2,
                    Red_Chi2_Top => Red_Chi2_Top2,
                    Norman       => Height2);

      if Check_Chi2_Value (Chi2_Value => Red_Chi2_Top1) and
        Check_Chi2_Value (Chi2_Value =>  Red_Chi2_Top2) then

         if Red_Chi2_Top1 < Red_Chi2_Top2 then
            Red_Chi2_Top := Red_Chi2_Top1;

            --  Set an interim value for key parameters
            FWHM_Main := FWHM_In1;
            Height_Main := Height1;

         else
            Red_Chi2_Top := Red_Chi2_Top2;

            --  Set an interim value for key parameters
            FWHM_Main   := FWHM_In2;
            Height_Main := Height2;

         end if;

         --  Select the lower of the interim valus of X(n) and X(n-1)
         if Red_Chi2_Top <= Red_Chi2_Top_Old then
            FWHM_Out    := FWHM_Main;
            Peak_Height := Height_Main;
         else
            --  If the old value is lower, restored previous values
            Red_Chi2_Top := Red_Chi2_Top_Old;
            Red_Chi2_Top_Old := Red_Chi2_Top_Old_Old;
         end if;

      end if;

   end Try_Curve_FWHM;

   -------------------------------------------------------------------
   --  Name       : Fit_Curve_FWHM
   --  Implementation Information: Includes engineering use print statements.
   -------------------------------------------------------------------
   procedure Fit_Curve_FWHM
     (Search_Array    : in  Region_Of_Interest.Region_Of_Interest_Type;
      Centroid        : in  Channel_Types.Extended_Channel_Type;
      Background      : in  Toolbox.Extended_Channel_Size;
      Height          : out Region_Of_Interest.Peak_Height_Type;
      Good_Fit        : out Boolean)
   is
      --  Local variables for varying the FWHM to fit the curve
      FWHM_Local       : Measurement_Peaks.ISO_FWHM_Type;
      FWHM1            : Measurement_Peaks.ISO_FWHM_Type;
      FWHM2            : Measurement_Peaks.ISO_FWHM_Type;

      FWHM_Inc         : FWHM_Incrementer_Type := FWHM_Incrementer_Type'Last;

      --  Chi square values of previous runs to store and compare against
      Red_Chi2_Top     : Mod_Types.Unsigned_64;
      Red_Chi2_Top_Old : Mod_Types.Unsigned_64 := 0;

      --  Normalisation factor of attempted curve fit
      Norman           : Region_Of_Interest.Peak_Height_Type;

      --  Required accuracy of the curve fit
      ACCURACY         : constant := Toolbox.MULT / 100;

      --  Flag for loop exitting
      Quit             : Boolean;

   begin
      Measurement_Peaks.Reset_FWHM;
      FWHM_Local := Measurement_Peaks.Get_FWHM;

      --  Plot gaussian curved based on initial values
      Gaussian_Inc (Search_Array => Search_Array,
                    Centroid     => Centroid,
                    Background   => Background,
                    FWHM         => FWHM_Local,
                    Red_Chi2_Top => Red_Chi2_Top,
                    Norman       => Norman);

      Height := Norman;

      if not Check_Chi2_Value (Chi2_Value => Red_Chi2_Top) then
         --  Our initial attempt is too far to be able to complete
         Height := 0;
         Good_Fit := False;

      else

         --  Incremental loop whilst the diffeence between X(n) and X(n-1) is greater
         --  than a specified value (the accuracy).
         while
           (abs (Long_Long_Integer (Red_Chi2_Top) - Long_Long_Integer
                 (Red_Chi2_Top_Old))) > ACCURACY and then
           FWHM_Inc > 1 loop

            --# assert Red_Chi2_Top < Mod_Types.Unsigned_64'Last / 2 and
            --#        Red_Chi2_Top_Old < Mod_Types.Unsigned_64'Last / 2;

            Adjust_FWHM (Current_Value => FWHM_Local,
                         Incrementer   => FWHM_Inc,
                         New_Value_1   => FWHM1,
                         New_Value_2   => FWHM2,
                         Fail          => Quit);

            exit when Quit;

            Try_Curve_FWHM (Search_Array       => Search_Array,
                            Centroid           => Centroid,
                            Background         => Background,
                            FWHM_In1           => FWHM1,
                            FWHM_In2           => FWHM2,
                            Red_Chi2_Top       => Red_Chi2_Top,
                            Red_Chi2_Top_Old   => Red_Chi2_Top_Old,
                            Peak_Height        => Height,
                            FWHM_Out           => FWHM_Local);

            --  Apply crude adjustment to speed up rate of convergence
            FWHM_Inc := FWHM_Incrementer_Type'
              (Update_Incrementer (Old_Chi2     => Red_Chi2_Top_Old,
                                   Current_Chi2 => Red_Chi2_Top,
                                   Old_Inc      => Mod_Types.Unsigned_32'(FWHM_Inc)));
         end loop;

         Check_Fit (Fit_Accuracy     => ACCURACY,
                    Red_Chi2_Top     => Red_Chi2_Top,
                    Red_Chi2_Top_Old => Red_Chi2_Top_Old,
                    Peak_Height      => Height,
                    Curve_Fitted     => Good_Fit);

         Measurement_Peaks.Set_FWHM (FWHM_Value => FWHM_Local);

         Dump_Curve_Fit_Data (Curve_Fit_Variable => "FWHM",
                              Curve_Fitted       => Good_Fit,
                              Peak_Height        => Height,
                              Red_Chi2_Top       => Red_Chi2_Top,
                              Red_Chi2_Top_Old   => Red_Chi2_Top_Old,
                              Incrementer        => FWHM_Inc);
      end if;

   end Fit_Curve_FWHM;

   -------------------------------------------------------------------
   --  Name       : Adjust_Background
   --  Implementation Information: Includes engineering use print statements.
   -------------------------------------------------------------------
   procedure Adjust_Background (Current_Value : in  Toolbox.Extended_Channel_Size;
                                Incrementer   : in  Bg_Incrementer_Type;
                                New_Value_1   : out Toolbox.Extended_Channel_Size;
                                New_Value_2   : out Toolbox.Extended_Channel_Size;
                                Fail          : out Boolean)
   is
   begin
      New_Value_1 := Toolbox.Extended_Channel_Size'Last;
      New_Value_2 := Toolbox.Extended_Channel_Size'Last;
      Fail := False;

      if Mod_Types.Unsigned_32'(Current_Value) <
        Mod_Types.Unsigned_32'(Toolbox.Extended_Channel_Size'First) + Incrementer then
         --  Background is too low (current value - incrementer < Bg_Incrementer_Type'First)
         Usart1.Send_String (Item => "Error: Curve Fit Background - Background is too low");
         Usart1.Send_Message_New_Line;

         Fail := True;

      elsif Mod_Types.Unsigned_32'(Current_Value) >
        Mod_Types.Unsigned_32'(Toolbox.Extended_Channel_Size'Last) - Incrementer then
         --  Background is too high (current value + incrementer < Bg_Incrementer_Type'Last)
         Usart1.Send_String (Item => "Error: Curve Fit Background - Background is too high");
         Usart1.Send_Message_New_Line;

         Fail := True;
      elsif (Long_Integer (Current_Value) - Long_Integer (Incrementer) < Toolbox.MULT) and then
        (Long_Integer (Current_Value) + Long_Integer (Incrementer) < Toolbox.MULT) then
         Usart1.Send_String
           (Item => "Error: Curve Fit Background - Incrementer makes Background too low");
         Usart1.Send_Message_New_Line;

         Fail := True;
      elsif Long_Integer (Current_Value) - Long_Integer (Incrementer) < Toolbox.MULT then
         --  Subtracting the Incrementer would cause the background to become negative,
         --  therefor set it to zero
         New_Value_1 := Toolbox.MULT;
         New_Value_2 := Toolbox.Extended_Channel_Size'(Mod_Types.Unsigned_32'(Current_Value) +
                                                         Mod_Types.Unsigned_32'(Incrementer));
      elsif Long_Integer (Current_Value) + Long_Integer (Incrementer) < Toolbox.MULT then
         --  Adding the Incrementer would cause the background to become negative,
         --  therefor set it to zero
         New_Value_1 := Toolbox.Extended_Channel_Size'(Mod_Types.Unsigned_32'(Current_Value) -
                                                         Mod_Types.Unsigned_32'(Incrementer));
         New_Value_2 := Toolbox.MULT;
      else
         --  Calculate the reduced chi square for values positioned +/-
         --  Inc either side

         --  Vary the Background
         New_Value_1 := Toolbox.Extended_Channel_Size'(Mod_Types.Unsigned_32'(Current_Value) -
                                                         Mod_Types.Unsigned_32'(Incrementer));
         New_Value_2 := Toolbox.Extended_Channel_Size'(Mod_Types.Unsigned_32'(Current_Value) +
                                                         Mod_Types.Unsigned_32'(Incrementer));
      end if;
   end Adjust_Background;

   -------------------------------------------------------------------
   --  Name       : Try_Curve_Background
   --  Implementation Information: None.
   -------------------------------------------------------------------
   procedure Try_Curve_Background
     (Search_Array       : in     Region_Of_Interest.Region_Of_Interest_Type;
      Centroid           : in     Channel_Types.Extended_Channel_Type;
      Background_In1     : in     Toolbox.Extended_Channel_Size;
      Background_In2     : in     Toolbox.Extended_Channel_Size;
      FWHM               : in     Measurement_Peaks.ISO_FWHM_Type;
      Red_Chi2_Top       : in out Mod_Types.Unsigned_64;
      Red_Chi2_Top_Old   : in out Mod_Types.Unsigned_64;
      Background_Out     : in out Toolbox.Extended_Channel_Size;
      Peak_Height        :    out Region_Of_Interest.Peak_Height_Type)

   is
      --  Chi square values of previous runs to store and compare against
      Red_Chi2_Top_Old_Old : Mod_Types.Unsigned_64;
      Red_Chi2_Top1        : Mod_Types.Unsigned_64;
      Red_Chi2_Top2        : Mod_Types.Unsigned_64;

      --  Local variables for varying the Background to fit the curve
      Bg1                  : Toolbox.Extended_Channel_Size;
      Bg2                  : Toolbox.Extended_Channel_Size;
      Background_Main      : Toolbox.Extended_Channel_Size;

      --  Local variables for storing heights for attempting to fit the curve
      Height1              : Region_Of_Interest.Peak_Height_Type;
      Height2              : Region_Of_Interest.Peak_Height_Type;
      Height_Main          : Region_Of_Interest.Peak_Height_Type;

   begin
      --  Store old values
      Red_Chi2_Top_Old_Old := Red_Chi2_Top_Old;
      Red_Chi2_Top_Old := Red_Chi2_Top;

      Peak_Height := 0;
      Bg1 := Background_In1;
      Bg2 := Background_In2;

      Gaussian_Inc (Search_Array => Search_Array,
                    Centroid     => Centroid,
                    Background   => Bg1,
                    FWHM         => FWHM,
                    Red_Chi2_Top => Red_Chi2_Top1,
                    Norman       => Height1);

      Gaussian_Inc (Search_Array => Search_Array,
                    Centroid     => Centroid,
                    Background   => Bg2,
                    FWHM         => FWHM,
                    Red_Chi2_Top => Red_Chi2_Top2,
                    Norman       => Height2);

      if Check_Chi2_Value (Chi2_Value => Red_Chi2_Top1) and
        Check_Chi2_Value (Chi2_Value =>  Red_Chi2_Top2) then

         if Red_Chi2_Top1 < Red_Chi2_Top2 then
            Red_Chi2_Top := Red_Chi2_Top1;

            --  Set an interim value for key parameters
            Background_Main := Bg1;
            Height_Main := Height1;

         else
            Red_Chi2_Top := Red_Chi2_Top2;

            --  Set an interim value for key parameters
            Background_Main := Bg2;
            Height_Main := Height2;

            --  Note don't change the direction of the adjustment
         end if;

         --  Select the lower of the interim valus of X(n) and X(n-1)
         if Red_Chi2_Top <= Red_Chi2_Top_Old then
            Background_Out := Background_Main;
            Peak_Height := Height_Main;
         else
            --  If the old value is lower, restored previous values
            Red_Chi2_Top := Red_Chi2_Top_Old;
            Red_Chi2_Top_Old := Red_Chi2_Top_Old_Old;
         end if;
      end if;

   end Try_Curve_Background;

   -------------------------------------------------------------------
   --  Name       : Fit_Curve_Background
   --  Implementation Information: Includes engineering use print statements.
   -------------------------------------------------------------------
   procedure Fit_Curve_Background
     (Search_Array    : in Region_Of_Interest.Region_Of_Interest_Type;
      Centroid        : in Channel_Types.Extended_Channel_Type;
      Background      : in out Toolbox.Extended_Channel_Size;
      Height          : out Region_Of_Interest.Peak_Height_Type;
      Good_Fit        : out Boolean)
   is
      --  Local variables for varying the Background to fit the curve
      Bg1              : Toolbox.Extended_Channel_Size;
      Bg2              : Toolbox.Extended_Channel_Size;

      --  Incrementer to vary the curve fit parameters by
      Bg_Inc           : Bg_Incrementer_Type;

      --  Chi square values of previous runs to store and compare against
      Red_Chi2_Top     : Mod_Types.Unsigned_64;
      Red_Chi2_Top_Old : Mod_Types.Unsigned_64 := 0;

      --  Normalisation factor of attempted curve fit
      Norman           : Region_Of_Interest.Peak_Height_Type;

      --  Required accuracy of the curve fit
      ACCURACY         : constant := Toolbox.MULT / 100;

      --  Flag for loop exitting
      Quit             : Boolean;
   begin

      if Background > Bg_Incrementer_Type'Last then
         Bg_Inc := Bg_Incrementer_Type'Last;
      else
         Bg_Inc := Background - Toolbox.MULT;
      end if;

      --  Plot gaussian curved based on initial values
      Gaussian_Inc (Search_Array => Search_Array,
                    Centroid     => Centroid,
                    Background   => Background,
                    FWHM         => Measurement_Peaks.Get_FWHM,
                    Red_Chi2_Top => Red_Chi2_Top,
                    Norman       => Norman);

      Height := Norman;

      if not Check_Chi2_Value (Chi2_Value => Red_Chi2_Top) then
         --  Our initial attempt is too far to be able to complete
         Height := 0;
         Good_Fit := False;

      else

         --  Incremental loop whilst the diffeence between X(n) and X(n-1) is greater
         --  than a specified value (the accuracy).
         while
           (abs (Long_Long_Integer (Red_Chi2_Top) -
                   Long_Long_Integer (Red_Chi2_Top_Old))) > ACCURACY and then
           Bg_Inc > 1 loop

            Adjust_Background (Current_Value => Background,
                               Incrementer   => Bg_Inc,
                               New_Value_1   => Bg1,
                               New_Value_2   => Bg2,
                               Fail          => Quit);

            --# assert Red_Chi2_Top < Mod_Types.Unsigned_64'Last / 2 and
            --#        Red_Chi2_Top_Old < Mod_Types.Unsigned_64'Last / 2 and
            --#        Bg1 >= Toolbox.MULT and
            --#        Bg2 >= Toolbox.MULT and
            --#        Background >= Toolbox.MULT;
            exit when Quit;

            Try_Curve_Background (Search_Array     => Search_Array,
                                  Centroid         => Centroid,
                                  Background_In1   => Bg1,
                                  Background_In2   => Bg2,
                                  FWHM             => Measurement_Peaks.Get_FWHM,
                                  Red_Chi2_Top     => Red_Chi2_Top,
                                  Red_Chi2_Top_Old => Red_Chi2_Top_Old,
                                  Background_Out   => Background,
                                  Peak_Height      => Height);

            --  Apply crude adjustment to speed up rate of convergence
            Bg_Inc := Bg_Incrementer_Type'
              (Update_Incrementer (Old_Chi2     => Red_Chi2_Top_Old,
                                   Current_Chi2 => Red_Chi2_Top,
                                   Old_Inc      => Mod_Types.Unsigned_32'(Bg_Inc)));
         end loop;

         Check_Fit (Fit_Accuracy     => ACCURACY,
                    Red_Chi2_Top     => Red_Chi2_Top,
                    Red_Chi2_Top_Old => Red_Chi2_Top_Old,
                    Peak_Height      => Height,
                    Curve_Fitted     => Good_Fit);

         Dump_Curve_Fit_Data (Curve_Fit_Variable => "Background",
                              Curve_Fitted       => Good_Fit,
                              Peak_Height        => Height,
                              Red_Chi2_Top       => Red_Chi2_Top,
                              Red_Chi2_Top_Old   => Red_Chi2_Top_Old,
                              Incrementer        => Bg_Inc);
      end if;

   end Fit_Curve_Background;

end Measurement_Peaks.Curve_Fit;
