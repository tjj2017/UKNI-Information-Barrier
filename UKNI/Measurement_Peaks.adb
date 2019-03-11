----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Measurement_Peaks
--  Stored Filename: $Id: Measurement_Peaks.adb 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Created By: C Marsh
--  Date Created: 15/11/13
--  Description: Package container for the definition of a isotopic peaks
----------------------------------------------------------------------

package body Measurement_Peaks
--# own State is ISO_FWHM;
is

   -------------------------------------------------------------------
   --  Variables
   -------------------------------------------------------------------

   --  FWHM used when calculating the isotopics
   ISO_FWHM : ISO_FWHM_Type := FWHM_DEFAULT;
   -------------------------------------------------------------------
   --  Subprograms
   -------------------------------------------------------------------

   -------------------------------------------------------------------
   --  Name       : Get_FWHM
   --  Implementation Information: None.
   -------------------------------------------------------------------
   function Get_FWHM return ISO_FWHM_Type
   --# global in ISO_FWHM;
   is
   begin
      return ISO_FWHM;
   end Get_FWHM;

   -------------------------------------------------------------------
   --  Name       : Set_FWHM
   --  Implementation Information: None.
   -------------------------------------------------------------------
   procedure Set_FWHM (FWHM_Value : in ISO_FWHM_Type)
   --# global out ISO_FWHM;
   --# derives ISO_FWHM from FWHM_Value;
   is
   begin
      ISO_FWHM := FWHM_Value;
   end Set_FWHM;

   -------------------------------------------------------------------
   --  Name       : Reset_FWHM
   --  Implementation Information: None.
   -------------------------------------------------------------------
   procedure Reset_FWHM
   --# global out ISO_FWHM;
   --# derives ISO_FWHM from ;
   is
   begin
      ISO_FWHM := FWHM_DEFAULT;
   end Reset_FWHM;

   -------------------------------------------------------------------
   --  Name       : Calculate_Ratio
   --  Implementation Information: None.
   -------------------------------------------------------------------
   function Calculate_Ratio (Pu240_Height   : in     Region_Of_Interest.Peak_Height_Type;
                             Pu239_Height   : in     Region_Of_Interest.Peak_Height_Type) return Mod_Types.Unsigned_32
   is
      --  The ratio multiplier is calculated as (the half life of Pu240 / Branching Ratio of Pu240) /
      --                                        (the half life of Pu239 / Branching Ratio of Pu239)
      RATIO_MULT : constant := 5333;
   begin
      return Mod_Types.Unsigned_32'((Pu240_Height * RATIO_MULT)/ Pu239_Height);
   end Calculate_Ratio;

end Measurement_Peaks;
