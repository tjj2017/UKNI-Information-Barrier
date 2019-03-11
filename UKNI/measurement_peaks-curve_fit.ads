----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Measurement_Peaks.Curve_Fit
--  Stored Filename: $Id: measurement_peaks-curve_fit.ads 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Created By: C Marsh
--  Date Created: 15/11/13
--  <description>
--               Package container for curve fitting of the isotopic peaks
--  </description>
----------------------------------------------------------------------
with Mod_Types,
     Region_Of_Interest,
     Toolbox;

--# inherit Channel_Types,
--#         Measurement_Peaks,
--#         Mod_Types,
--#         Region_Of_Interest,
--#         Toolbox,
--#         Toolbox.Maths,
--#         Usart1;

package Measurement_Peaks.Curve_Fit is

   -------------------------------------------------------------------
   --  Types
   -------------------------------------------------------------------

   --  Normalisation occurs over the range 0 .. MULT, which is equivalent
   --  to 0 .. 1 if not multiplying up
   subtype Normalized_Height_Type is Mod_Types.Unsigned_16 range 0 .. Toolbox.MULT;

   -------------------------------------------------------------------
   --  Subprograms
   -------------------------------------------------------------------

   -------------------------------------------------------------------
   --  <name> Get_Start_Channel </name>
   --  <description>
   --    Calculate the integer start channel associated with the passed in
   --  * centroid location
   --  </description>
   --  <input name="Centroid">
   --     The location of the centroid of the curve [@*mult]
   --  </input><
   --  <Returns>
   --     The start channel for analysis [@mult]
   --  <Returns>
   -------------------------------------------------------------------
   function Get_Start_Channel (Centroid : in Channel_Types.Extended_Channel_Type)
                               return Channel_Types.Extended_Channel_Type;
   --# pre Centroid > Channel_Types.Extended_Channel_Type'First + Toolbox.PEAK_EVAL_GUARD and
   --#     Centroid < Channel_Types.Extended_Channel_Type'Last  - Toolbox.PEAK_EVAL_GUARD;
   --# return M => (M > 0 and
   --#              M + (Toolbox.PEAK_EVAL_WIDTH/2) * Toolbox.MULT <= Centroid + Toolbox.MULT and
   --#              M + (Toolbox.PEAK_EVAL_WIDTH/2) * Toolbox.MULT >= Centroid - Toolbox.MULT and
   --#              M <= Channel_Types.Extended_Channel_Type'Last - Toolbox.MULT);

   -------------------------------------------------------------------
   --  <name> Fit_Curve_FWHM </name>
   --  <description> Fits a guassian curve based on changing the FWHM
   --  </description>
   --  <input name="Search_Array">
   --     The region of interest to fit a curve to [@*real]
   --  </input><input name="Centroid">
   --     The location of the centroid of the curve [@*mult]
   --  </input><input name="Background">
   --     The background per channel of the search array [@*mult]
   --  </input>
   --  <output name="Height">
   --     The height of the curve [@mult]
   --  </output><output name="Good_Fit">
   --     Boolean flag to state wether or not a good fit has been achieved
   --  </output>
   -------------------------------------------------------------------
   procedure Fit_Curve_FWHM (Search_Array    : in     Region_Of_Interest.Region_Of_Interest_Type;
                             Centroid        : in     Channel_Types.Extended_Channel_Type;
                             Background      : in     Toolbox.Extended_Channel_Size;
                             Height          : out    Region_Of_Interest.Peak_Height_Type;
                             Good_Fit        : out    Boolean);
   --# global out Measurement_Peaks.State;
   --# derives Good_Fit,
   --#         Height,
   --#         Measurement_Peaks.State from Background,
   --#                                      Centroid,
   --#                                      Search_Array;
   --# pre Centroid > Channel_Types.Extended_Channel_Type'First + Toolbox.PEAK_EVAL_GUARD and
   --#     Centroid < Channel_Types.Extended_Channel_Type'Last  - Toolbox.PEAK_EVAL_GUARD and
   --#     (for all I in Channel_Types.Data_Channel_Number range
   --#               Search_Array'First .. Search_Array'Last =>
   --#                    (Mod_Types.Unsigned_32 (Search_Array(I)) * Toolbox.MULT -
   --#                          Background >= 0)) and
   --#     Search_Array'Length(1) >= Toolbox.PEAK_EVAL_WIDTH + 1 and
   --#     (for all I in Channel_Types.Data_Channel_Number range
   --#               Search_Array'First .. Search_Array'Last =>
   --#                    (Mod_Types.Unsigned_32 (Search_Array(I)) /= 0)) and
   --#     Background >= Toolbox.MULT;

   -------------------------------------------------------------------
   --  <name> Fit_Curve_Background </name>
   --  <description> Fits a guassian curve based on changing the Background
   --  </description>
   --  <input name="Search_Array">
   --     The region of interest to fit a curve to [@*real]
   --  </input><input name="Centroid">
   --     The location of the centroid of the curve [@*mult]
   --  </input><input name="Background">
   --     The background per channel of the search array [@*mult]
   --  </input>
   --  <output name="Background">
   --     The background per channel of the search array [@*mult]
   --  </output><output name="Height">
   --     The height of the curve [@mult]
   --  </output><output name="Good_Fit">
   --     Boolean flag to state wether or not a good fit has been achieved
   --  </output>
   -------------------------------------------------------------------
   procedure Fit_Curve_Background
     (Search_Array    : in     Region_Of_Interest.Region_Of_Interest_Type;
      Centroid        : in     Channel_Types.Extended_Channel_Type;
      Background      : in out Toolbox.Extended_Channel_Size;
      Height          :    out Region_Of_Interest.Peak_Height_Type;
      Good_Fit        :    out Boolean);
   --# global in Measurement_Peaks.State;
   --# derives Background,
   --#         Good_Fit,
   --#         Height     from Background,
   --#                         Centroid,
   --#                         Measurement_Peaks.State,
   --#                         Search_Array;
   --# pre Centroid > Channel_Types.Extended_Channel_Type'First + Toolbox.PEAK_EVAL_GUARD and
   --#     Centroid < Channel_Types.Extended_Channel_Type'Last  - Toolbox.PEAK_EVAL_GUARD and
   --#     (for all I in Channel_Types.Data_Channel_Number range
   --#               Search_Array'First .. Search_Array'Last =>
   --#                    (Mod_Types.Unsigned_32 (Search_Array(I)) * Toolbox.MULT
   --#                       - Background >= 0)) and
   --#     Search_Array'Length(1) >= Toolbox.PEAK_EVAL_WIDTH + 1 and
   --#     (for all I in Channel_Types.Data_Channel_Number range
   --#               Search_Array'First .. Search_Array'Last =>
   --#                    (Mod_Types.Unsigned_32 (Search_Array(I)) /= 0)) and
   --#     Background >= Toolbox.MULT;

private

   --  Types to hold modelled aspects of the peak
   --  The size of all the modelled peaks is determined by Toolbox.PEAK_EVAL_WIDTH
   subtype Modelled_Peak_Size_Type is Mod_Types.Unsigned_8 range 0 .. Toolbox.PEAK_EVAL_WIDTH;

   --  Array type declaration to hold a guassian array
   type Normalised_Modelled_Peak_Type is array (Modelled_Peak_Size_Type) of
     Normalized_Height_Type;

   --  The modelled peak is the normalized peak * the height of the peak + background
   subtype Expanded_Peak_Type is Mod_Types.Unsigned_64 range 0 ..
     (Mod_Types.Unsigned_64 (Normalized_Height_Type'Last) *
          Mod_Types.Unsigned_64 (Region_Of_Interest.Peak_Height_Type'Last) +
          Mod_Types.Unsigned_64 (Toolbox.Extended_Channel_Size'Last));

   --  Worst case for Chi2 occurs when the Chi2 is comprised of the variance squared
   subtype Chi2_Type is Mod_Types.Unsigned_64 range 0 ..
     (Mod_Types.Unsigned_64'(Expanded_Peak_Type'Last) *
          Mod_Types.Unsigned_64'(Expanded_Peak_Type'Last));

   --  Arrays types to hold the calculated information
   type Chi2_Array_Type is array (Modelled_Peak_Size_Type) of Chi2_Type;

   --  Incrementer types to vary the curve fit parameters by
   --  Starting value is 0.18 [@ * mult]
   subtype FWHM_Incrementer_Type is Mod_Types.Unsigned_32 range
     0 .. 2949;

   subtype Bg_Incrementer_Type is Mod_Types.Unsigned_32 range
     0 .. Toolbox.MULT * 3277;

   -------------------------------------------------------------------
   --  Constants
   -------------------------------------------------------------------

   --  The allowable FWHM ranges from 6 ..9 (@*MULT).
   --  The maximum difference between the integer peak channel and the peak
   --  channel is 0.5
   --  Therefor the lowest point that the max point of the curve can be is
   --  given by exp((-1*4*log(2) / 6^2) * 0.5^2) = c.  0.9809
   --  This equates to 16072 (@*mult)
   MODELLED_PEAK_MINIMUM_HEIGHT : constant := 16072;

   -------------------------------------------------------------------
   --  Subprograms
   -------------------------------------------------------------------

   -------------------------------------------------------------------
   --  <name> Get_Max </name>
   --  <description> Returns the maximum value from the passed in array
   --  </description>
   --  <input name="Search">
   --     The array to search
   --  </input>
   --  </returns>
   --     The maximum value in the array
   --  </output>
   -------------------------------------------------------------------
   function Get_Max (Search : in  Region_Of_Interest.Region_Of_Interest_Type)
                     return Mod_Types.Unsigned_16;
   --# return M => (for all I in Channel_Types.Data_Channel_Number range
   --#               Search'First .. Search'Last => (Search(I) <= M));
   pragma Inline (Get_Max);

   -------------------------------------------------------------------
   --  <name> Generate_Gaussian </name>
   --  <description> Generate a guassian peak, and also return the max height
   --                of the peak
   --  </description>
   --  <input name="Centroid_Location">
   --     The location of the centroid of the curve [@*mult]
   --  </input><input name="St_Channel">
   --     The start channel for the generated peak
   --  </input><input name="Gaussian_Constant">
   --     The Gaussian Constant for the generated peak
   --  </input>
   --  </output name="Guassian_Peak>
   --     Array to hold the guassian peak created by the procedure
   --  </output></output name="Peak_Max>
   --     The maximum height of the guassian curve
   --  </output>
   -------------------------------------------------------------------
   procedure Generate_Gaussian (Centroid_Location : in  Channel_Types.Extended_Channel_Type;
                                St_Channel        : in  Channel_Types.Extended_Channel_Type;
                                Gaussian_Constant : in  Measurement_Peaks.G_Const_Type;
                                Gaussian_Peak     : out Normalised_Modelled_Peak_Type;
                                Peak_Max          : out Normalized_Height_Type);
   --# derives Gaussian_Peak,
   --#         Peak_Max      from Centroid_Location,
   --#                            Gaussian_Constant,
   --#                            St_Channel;
   --# pre Centroid_Location > Channel_Types.Extended_Channel_Type'First +
   --#                             Toolbox.PEAK_EVAL_GUARD and
   --#     Centroid_Location < Channel_Types.Extended_Channel_Type'Last  -
   --#                             Toolbox.PEAK_EVAL_GUARD and
   --#     St_Channel + (Toolbox.PEAK_EVAL_WIDTH/2) * Toolbox.MULT >= Centroid_Location -
   --#                             Toolbox.MULT and
   --#     St_Channel + (Toolbox.PEAK_EVAL_WIDTH/2) * Toolbox.MULT <= Centroid_Location +
   --#                             Toolbox.MULT and
   --#     St_Channel > 0;
   --# post Peak_Max >= MODELLED_PEAK_MINIMUM_HEIGHT;
   pragma Inline (Generate_Gaussian);

   -------------------------------------------------------------------
   --  <name> Calculate_Chi </name>
   --  <description> Calculate the Chi Squared array for the passed in
   --                region of interest and gaussian curve
   --  </description>
   --  <input name="Search_Array">
   --     The region of interest to fit a curve to [@*real]
   --  </input><input name="Gaussian_Peak">
   --     Array to hold the guassian peak created by the procedure
   --  </input><input name="Peak_Max">
   --     The maximum height of the guassian curve
   --  </input><input name="Background">
   --      The background per channel of the search array [@*mult]
   --  </input></input name="Array_Start>
   --     The start address to analyse of the gaussian peak
   --  </output></output name="Array_End>
   --     The end address to analyse of the gaussian peak
   --  </output>
   --  <returns>
   --     The array containing the chi squared result for each element
   --     from Array_Start to Array_End
   --  </returns>
   -------------------------------------------------------------------
   function Calculate_Chi (Search_Array  : in Region_Of_Interest.Region_Of_Interest_Type;
                           Gaussian_Peak : in Normalised_Modelled_Peak_Type;
                           Peak_Max      : in Region_Of_Interest.Peak_Height_Type;
                           Background    : in Toolbox.Extended_Channel_Size;
                           Array_Start   : in Modelled_Peak_Size_Type;
                           Array_End     : in Modelled_Peak_Size_Type) return Chi2_Array_Type;
   --# pre Array_Start < Array_End and
   --#     (for all I in Channel_Types.Data_Channel_Number range
   --#               Search_Array'First .. Search_Array'Last =>
   --#                    (Mod_Types.Unsigned_32 (Search_Array(I))
   --#                           * Toolbox.MULT - Background >= 0)) and
   --#     Search_Array'Length(1) >= Toolbox.PEAK_EVAL_WIDTH + 1 and
   --#     (for all I in Channel_Types.Data_Channel_Number range
   --#               Search_Array'First .. Search_Array'Last =>
   --#                    (Mod_Types.Unsigned_32 (Search_Array(I)) /= 0))and
   --#     Background >= Toolbox.MULT;
   pragma Inline (Calculate_Chi);

   -------------------------------------------------------------------
   --  <name> Gaussian_Inc </name>
   --  <description> Fits a guassian curve based on user input parameters
   --  </description>
   --  <input name="Search_Array">
   --     The region of interest to fit a curve to [@*real]
   --  </input><input name="Centroid">
   --     The location of the centroid of the curve [@*mult]
   --  </input><input name="Background">
   --     The background per channel of the search array [@*mult]
   --  </input><input name="FWHM">
   --     The FWHM of the curve [@*mult]
   --  </input>
   --  <output name="Red_Chi2_Top">
   --     The reduced chi square top value (i.e. how well the top fits the curve)  [@mult]
   --  </output><output name="Norman">
   --     The normalisation factor applied to the curve.  (i.e. the height of the curve)  [@mult]
   --  </output>
   -------------------------------------------------------------------
   procedure Gaussian_Inc (Search_Array : in  Region_Of_Interest.Region_Of_Interest_Type;
                           Centroid     : in  Channel_Types.Extended_Channel_Type;
                           Background   : in  Toolbox.Extended_Channel_Size;
                           FWHM         : in  Measurement_Peaks.ISO_FWHM_Type;
                           Red_Chi2_Top : out Mod_Types.Unsigned_64;
                           Norman       : out Region_Of_Interest.Peak_Height_Type);
   --# derives Norman,
   --#         Red_Chi2_Top from Background,
   --#                           Centroid,
   --#                           FWHM,
   --#                           Search_Array;
   --# pre Centroid > Channel_Types.Extended_Channel_Type'First + Toolbox.PEAK_EVAL_GUARD and
   --#     Centroid < Channel_Types.Extended_Channel_Type'Last  - Toolbox.PEAK_EVAL_GUARD and
   --#     (for all I in Channel_Types.Data_Channel_Number range
   --#               Search_Array'First .. Search_Array'Last =>
   --#                    (Mod_Types.Unsigned_32 (Search_Array(I)) * Toolbox.MULT -
   --#                           Background >= 0)) and
   --#     Search_Array'Length(1) >= Toolbox.PEAK_EVAL_WIDTH + 1 and
   --#     (for all I in Channel_Types.Data_Channel_Number range
   --#               Search_Array'First .. Search_Array'Last =>
   --#                    (Mod_Types.Unsigned_32 (Search_Array(I)) /= 0))and
   --#     Background >= Toolbox.MULT;

   -------------------------------------------------------------------
   --  <name> Update_Incrementer </name>
   --  <description> Update the incrementer depending on the difference
   --                in the reduced chi square term from previous to current
   --                iteration
   --  </description>
   --  <input name="Old_Chi2">
   --     The value of the reduced chi square on the previous pass
   --  </input>
   --  <input name="Current_Chi2">
   --     The value of the reduced chi square on the current pass
   --  </input>
   --  <returns="Old_Inc">
   --     The value of the current value of the incrementer
   --  </input>
   --  <returns>
   --     The new value for the incrementer
   --  </returns>
   -------------------------------------------------------------------
   function Update_Incrementer (Old_Chi2     : in Mod_Types.Unsigned_64;
                                Current_Chi2 : in Mod_Types.Unsigned_64;
                                Old_Inc      : in Mod_Types.Unsigned_32)
                                return Mod_Types.Unsigned_32;
   --# pre Current_Chi2 < Mod_Types.Unsigned_64'Last / 2 and
   --#     Old_Chi2 < Mod_Types.Unsigned_64'Last / 2 and
   --#     Old_Inc <= Bg_Incrementer_Type'Last;
   --# return M => M <= Old_Inc;

   -------------------------------------------------------------------
   --  <name> Dump_Curve_Fit_Data </name>
   --  <description> Dump the results of the curve fit to the engineering debug port
   --  </description>
   --  <input name="Curve_Fit_Variable">
   --     String stating whether the curve is being fitted by modifying the FWHM
   --     or the background
   --  </input><input name="Curve_Fitted">
   --     Boolean flag indicating whether the curve fit was successful
   --  </input><input name="Peak_Height">
   --     The height of the fitted peak
   --  </input><input name="Red_Chi2_Top">
   --     The value of the reduced chi squared top of the current iteration
   --  </input><input name="Red_Chi2_Top_Old">
   --     The value of the reduced chi squared top of the previously stored iteration
   --  </input><input name="Incrementer">
   --     The final value of the incrementer
   --  </input>
   -------------------------------------------------------------------
   procedure Dump_Curve_Fit_Data (Curve_Fit_Variable : in String;
                                  Curve_Fitted       : in Boolean;
                                  Peak_Height        : in Region_Of_Interest.Peak_Height_Type;
                                  Red_Chi2_Top       : in Mod_Types.Unsigned_64;
                                  Red_Chi2_Top_Old   : in Mod_Types.Unsigned_64;
                                  Incrementer        : in Mod_Types.Unsigned_32);
   --# derives null from Curve_Fitted,
   --#                   Curve_Fit_Variable,
   --#                   Incrementer,
   --#                   Peak_Height,
   --#                   Red_Chi2_Top,
   --#                   Red_Chi2_Top_Old;

   -------------------------------------------------------------------
   --  <name> Check_Fit </name>
   --  <description> Check whether the fitted curve meets the defined criteria for a good fit
   --  </description>
   --  <input name="Red_Chi2_Top">
   --     The value of the reduced chi squared top of the current iteration
   --  </input><input name="Red_Chi2_Top_Old">
   --     The value of the reduced chi squared top of the previously stored iteration
   --  </input><input name="Peak_Height">
   --     The height of the peak
   --  </input>
   --  <output name="Peak_Height">
   --     The height of the peak is set to 0 if a good fit is not achieved
   --  </output><output name="Curve_Fitted">
   --     Boolean flag indicating whether the curve fit was successful
   --  </output>
   -------------------------------------------------------------------
   procedure Check_Fit (Fit_Accuracy       : in     Mod_Types.Unsigned_32;
                        Red_Chi2_Top       : in     Mod_Types.Unsigned_64;
                        Red_Chi2_Top_Old   : in     Mod_Types.Unsigned_64;
                        Peak_Height        : in out Region_Of_Interest.Peak_Height_Type;
                        Curve_Fitted       :    out Boolean);
   --# derives Curve_Fitted from Fit_Accuracy,
   --#                           Red_Chi2_Top,
   --#                           Red_Chi2_Top_Old &
   --#         Peak_Height  from *,
   --#                           Fit_Accuracy,
   --#                           Red_Chi2_Top,
   --#                           Red_Chi2_Top_Old;

   -------------------------------------------------------------------
   --  <name> Check_Chi2_Value </name>
   --  <description> Check whether the chi2 value is within range to allow fit to continue
   --  </description>
   --  <input name="Chi2_Value">
   --     The value of the reduced chi squared top
   --  </input
   --  <returns>
   --     whether the chi2 value is in range
   --  </returns>
   -------------------------------------------------------------------
   function Check_Chi2_Value (Chi2_Value : in Mod_Types.Unsigned_64) return Boolean;
   --# return Chi2_Value < Mod_Types.Unsigned_64'Last / 2;

   -------------------------------------------------------------------
   --  <name> Adjust_FWHM </name>
   --  <description> Given an input value to the FWHM, calculate the values when
   --                applying the offset
   --  </description>
   --  <input name="Current_Value">
   --     The starting value of FWHM
   --  </input><input name="Incrementer">
   --     The value to adjust the FWHM by
   --  </input>
   --  <output name="New_Value_1">
   --     The result of adding the incrementer to the current value
   --  </output><output name="New_Value_2">
   --     The result of sunbtracting the incrementer to the current value
   --  </output><output name="Fail">
   --     Whether the incrementer has been applied
   --  </output>
   -------------------------------------------------------------------
   procedure Adjust_FWHM (Current_Value : in  Measurement_Peaks.ISO_FWHM_Type;
                          Incrementer   : in  FWHM_Incrementer_Type;
                          New_Value_1   : out Measurement_Peaks.ISO_FWHM_Type;
                          New_Value_2   : out Measurement_Peaks.ISO_FWHM_Type;
                          Fail          : out Boolean);
   --# derives Fail,
   --#         New_Value_1,
   --#         New_Value_2 from Current_Value,
   --#                          Incrementer;

   -------------------------------------------------------------------
   --  <name> Adjust_Background </name>
   --  <description> Given an input value to the background, calculate the
   --  *             values when applying the offset
   --  </description>
   --  <input name="Current_Value">
   --     The starting value of the backgroudn
   --  </input><input name="Incrementer">
   --     The value to adjust the background by
   --  </input>
   --  <output name="New_Value_1">
   --     The result of adding the incrementer to the current value
   --  </output><output name="New_Value_2">
   --     The result of sunbtracting the incrementer to the current value
   --  </output><output name="Fail">
   --     Whether the incrementer has been applied
   --  </output>
   -------------------------------------------------------------------
   procedure Adjust_Background (Current_Value : in  Toolbox.Extended_Channel_Size;
                                Incrementer   : in  Bg_Incrementer_Type;
                                New_Value_1   : out Toolbox.Extended_Channel_Size;
                                New_Value_2   : out Toolbox.Extended_Channel_Size;
                                Fail          : out Boolean);
   --# derives Fail,
   --#         New_Value_1,
   --#         New_Value_2 from Current_Value,
   --#                          Incrementer;
   --# post New_Value_1 >= Toolbox.MULT and
   --#      New_Value_2 >= Toolbox.MULT;

   -------------------------------------------------------------------
   --  <name> Try_Curve_FWHM </name>
   --  <description> Perform a single attempt to fit a curve by varying the FWHM
   --  </description>
   --  <input name="Search_Array">
   --     The region of interest to fit a curve to [@*real]
   --  </input><input name="Centroid">
   --     The location of the centroid of the curve [@*mult]
   --  </input><input name="FWHM_In1">
   --     The starting value of FWHM_In1
   --  </input><input name="FWHM_In2">
   --     The starting value of FWHM_In2
   --  </input><input name="Background">
   --     The background level
   --  </input><input name="Incrementer">
   --     The value the FWHM to adjusted by
   --  </input><input name="Red_Chi2_Top">
   --     The value of the reduced chi squared top of the current iteration
   --  </input><input name="Red_Chi2_Top_Old">
   --     The value of the reduced chi squared top of the previously stored iteration
   --  </input>
   --  <output name="Red_Chi2_Top">
   --     The updated value of the reduced chi squared top of the current iteration
   --  </output><output name="Red_Chi2_Top_Old">
   --     The updated of the reduced chi squared top of the previously stored iteration
   --  </output><output name="FWHM_Out">
   --     The resultant value of FWHM_Out
   --  </output><output name="Peak_Height">
   --     The height of the peak
   --  </output>
   -------------------------------------------------------------------
   procedure Try_Curve_FWHM (Search_Array       : in     Region_Of_Interest.Region_Of_Interest_Type;
                             Centroid           : in     Channel_Types.Extended_Channel_Type;
                             Background         : in     Toolbox.Extended_Channel_Size;
                             FWHM_In1           : in     Measurement_Peaks.ISO_FWHM_Type;
                             FWHM_In2           : in     Measurement_Peaks.ISO_FWHM_Type;
                             Red_Chi2_Top       : in out Mod_Types.Unsigned_64;
                             Red_Chi2_Top_Old   : in out Mod_Types.Unsigned_64;
                             FWHM_Out           : in out Measurement_Peaks.ISO_FWHM_Type;
                             Peak_Height        :    out Region_Of_Interest.Peak_Height_Type);
   --# derives FWHM_Out,
   --#         Red_Chi2_Top,
   --#         Red_Chi2_Top_Old from *,
   --#                               Background,
   --#                               Centroid,
   --#                               FWHM_In1,
   --#                               FWHM_In2,
   --#                               Red_Chi2_Top,
   --#                               Search_Array &
   --#         Peak_Height      from Background,
   --#                               Centroid,
   --#                               FWHM_In1,
   --#                               FWHM_In2,
   --#                               Red_Chi2_Top,
   --#                               Search_Array;
   --# pre Centroid > Channel_Types.Extended_Channel_Type'First + Toolbox.PEAK_EVAL_GUARD and
   --#     Centroid < Channel_Types.Extended_Channel_Type'Last  - Toolbox.PEAK_EVAL_GUARD and
   --#     (for all I in Channel_Types.Data_Channel_Number range
   --#               Search_Array'First .. Search_Array'Last =>
   --#                    (Mod_Types.Unsigned_32 (Search_Array(I)) * Toolbox.MULT -
   --#                         Background >= 0)) and
   --#     Search_Array'Length(1) >= Toolbox.PEAK_EVAL_WIDTH + 1 and
   --#     (for all I in Channel_Types.Data_Channel_Number range
   --#               Search_Array'First .. Search_Array'Last =>
   --#                    (Mod_Types.Unsigned_32 (Search_Array(I)) /= 0)) and
   --#     Background >= Toolbox.MULT and
   --#     Red_Chi2_Top < Mod_Types.Unsigned_64'Last / 2 and
   --#     Red_Chi2_Top_Old < Mod_Types.Unsigned_64'Last / 2;
   --# post    Red_Chi2_Top < Mod_Types.Unsigned_64'Last / 2 and
   --#         Red_Chi2_Top_Old < Mod_Types.Unsigned_64'Last / 2;

   -------------------------------------------------------------------
   --  <name> Try_Curve_Background </name>
   --  <description> Perform a single attempt to fit a curve by varying the background
   --  </description>
   --  <input name="Search_Array">
   --     The region of interest to fit a curve to [@*real]
   --  </input><input name="Centroid">
   --     The location of the centroid of the curve [@*mult]
   --  </input><input name="Background_In1">
   --     The starting value of Background_In1
   --  </input><input name="Background_In2">
   --     The starting value of Background_In1
   --  </input><input name="FWHM">
   --     The background level
   --  </input><input name="Incrementer">
   --     The value the FWHM to adjusted by
   --  </input><input name="Red_Chi2_Top">
   --     The value of the reduced chi squared top of the current iteration
   --  </input><input name="Red_Chi2_Top_Old">
   --     The value of the reduced chi squared top of the previously stored iteration
   --  </input>
   --  <output name="Red_Chi2_Top">
   --     The updated value of the reduced chi squared top of the current iteration
   --  </output><output name="Red_Chi2_Top_Old">
   --     The updated of the reduced chi squared top of the previously stored iteration
   --  </output><output name="Background_Out">
   --     The resultant value of Background_Out
   --  </output><output name="Peak_Height">
   --     The height of the peak
   --  </output>
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
      Peak_Height        :    out Region_Of_Interest.Peak_Height_Type);
   --# derives Background_Out,
   --#         Red_Chi2_Top,
   --#         Red_Chi2_Top_Old from *,
   --#                               Background_In1,
   --#                               Background_In2,
   --#                               Centroid,
   --#                               FWHM,
   --#                               Red_Chi2_Top,
   --#                               Search_Array &
   --#         Peak_Height      from Background_In1,
   --#                               Background_In2,
   --#                               Centroid,
   --#                               FWHM,
   --#                               Red_Chi2_Top,
   --#                               Search_Array;
   --# pre Centroid > Channel_Types.Extended_Channel_Type'First + Toolbox.PEAK_EVAL_GUARD and
   --#     Centroid < Channel_Types.Extended_Channel_Type'Last  - Toolbox.PEAK_EVAL_GUARD and
   --#     (for all I in Channel_Types.Data_Channel_Number range
   --#               Search_Array'First .. Search_Array'Last =>
   --#                    (Mod_Types.Unsigned_32 (Search_Array(I)) * Toolbox.MULT - Background_In1 >= 0)) and
   --#     (for all I in Channel_Types.Data_Channel_Number range
   --#               Search_Array'First .. Search_Array'Last =>
   --#                    (Mod_Types.Unsigned_32 (Search_Array(I)) * Toolbox.MULT - Background_In2 >= 0)) and
   --#     Search_Array'Length(1) >= Toolbox.PEAK_EVAL_WIDTH + 1 and
   --#     (for all I in Channel_Types.Data_Channel_Number range
   --#               Search_Array'First .. Search_Array'Last =>
   --#                    (Mod_Types.Unsigned_32 (Search_Array(I)) /= 0)) and
   --#     Background_In1 >= Toolbox.MULT and
   --#     Background_In2 >= Toolbox.MULT and
   --#     Background_Out >= Toolbox.MULT and
   --#     Red_Chi2_Top < Mod_Types.Unsigned_64'Last / 2 and
   --#     Red_Chi2_Top_Old < Mod_Types.Unsigned_64'Last / 2;
   --# post    Red_Chi2_Top < Mod_Types.Unsigned_64'Last / 2 and
   --#         Red_Chi2_Top_Old < Mod_Types.Unsigned_64'Last / 2 and
   --#         Background_Out >= Toolbox.MULT;
end Measurement_Peaks.Curve_Fit;
