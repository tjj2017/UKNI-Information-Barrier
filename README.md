# UKNI-Information-Barrier

This respository contains a Git mirror of the UKNi Information Barrier source
code described here:

https://ukni.info/project/information-barrier/

This Git mirror is *not* intended for active development, it is simply taken
from a read-only mirror of the original code, accessible via git. It is in no
way associated with the original authors of the source code.

Copyright remains with the original authors.

# ASVAT changes to code

The source code in the distribution is not entirely consistent and
contains test code which uses types and subprograms not declared in
the main application code.  The main application source code also
includes embedded assembler code which is not supported by ASVAT.  The
gnat compiler used for ASVAT does not accept the assembler mnemonics
used either.  The distributed code assumes a Windows host.

All the directory references have been changed to Unix style
references.

For ASVAT the following test modules have been deleted:
ib_main.adb
main_cr.adb
main_cr-capture.adb

The following package bodies which contain assembler code inserts have
had "shadow" bodies in which the subprograms containing the assembler
inserts have been replaced either by a null procedure body or a
function which always returns True:
memory_checks.adb - has a shadow -> memory_checks.shw
timer.adb - has a shadow -> timer.shw

The replaced subprograms are used in setting up and testing the
specialist hardware.

The gprbuild file for the distribution uses a special compiler and
does not work with a standard gnat compiler so a new build file has
been produced:
ukni.gpr

ukni.gpr calls the standard gnat compiler and uses the shadows referred to
above rather than the code with the embedded assembler instructions.

The SPARK analysis still uses the original code and not the shadows
but this works only because the bodies of these packages have been
"hidden" from SPARK by a --# hide directive in the original distribution.

The package Usart1 appears to have a declaration and body of
subprogram Send_Message_Comma missing and a representative subprogram
has been added.

The declaration of subtype Cal_Offset_Type in calibration_peak.ads is missing from the
distribution and a representative subtype declaration has been added.

The declarations of subtypes ISO_FWH_Type and Extended_Channel_Type
are missing from package measurement_peaks.ads and representative
declarations have been added.

The commands for building and analysing the code have changed because
the original commands were MS Windows commands.  These changes are
documented in the updated file README.txt in the UKNI directory.

