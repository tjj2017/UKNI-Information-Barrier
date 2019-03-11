----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Timeouts
--  Stored Filename: $Id: timeouts.ads 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Created By: D Curtis
--  <description>
--               Constant definitions of times allocated to operations
--  </description>
----------------------------------------------------------------------

package Timeouts is

   --  Time to delay when checking for source activity
   DETECTOR_BUSY : constant := 5; -- 5 seconds

   --  Time to capture counts for the calibration routine
   CALIBRATION   : constant := 300; -- 5 minutes

   --  Time to capture counts for the measurement routine
   MEASUREMENT   : constant := 3600; -- 60 minutes

end Timeouts;
