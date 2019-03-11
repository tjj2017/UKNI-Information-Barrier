----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Registers
--  Stored Filename: $Id: registers.ads 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Created By: D Curtis
--  <description>
--               This package provides register location definitions
--  </description>
----------------------------------------------------------------------

package Registers is

   --  Definitions of setting ports to outputs and inputs
   DDR_OUTPUT : constant := 16#FF#;

   DDR_INPUT  : constant := 16#00#;

   ------------------------PORTS-----------------------------------------------

   --  Data direction register addresses
   DDRB       : constant := 16#24#;

   DDRE       : constant := 16#2D#;

   DDRG       : constant := 16#33#;

   DDRH       : constant := 16#101#;

   DDRJ       : constant := 16#104#;

   DDRK       : constant := 16#107#;

   --  Port in registers
   PINB       : constant := 16#23#;

   PING       : constant := 16#32#;

   PINH       : constant := 16#100#;

   PINJ       : constant := 16#103#;

   --  Port out registers
   PORTE      : constant := 16#2E#;

   PORTG      : constant := 16#34#;

   PORTJ      : constant := 16#105#;

   PORTK      : constant := 16#108#;

end Registers;
