
###############################################################################
 #
 #  This file is part of canu, a software program that assembles whole-genome
 #  sequencing reads into contigs.
 #
 #  This software is based on:
 #    'Celera Assembler' (http://wgs-assembler.sourceforge.net)
 #    the 'kmer package' (http://kmer.sourceforge.net)
 #  both originally distributed by Applera Corporation under the GNU General
 #  Public License, version 2.
 #
 #  Canu branched from Celera Assembler at its revision 4587.
 #  Canu branched from the kmer project at its revision 1994.
 #
 #  Modifications by:
 #
 #    Brian P. Walenz beginning on 2015-NOV-08
 #      are a 'United States Government Work', and
 #      are released in the public domain
 #
 #  File 'README.licenses' in the root directory of this distribution contains
 #  full conditions and disclaimers for each license.
 ##

package canu::HTML;

require Exporter;

@ISA    = qw(Exporter);
@EXPORT = qw(buildHTML);

use strict;

use File::Copy;
use File::Path qw(make_path remove_tree);

use canu::Defaults;
use canu::Execution;



sub copyFile ($$) {
    my $sPath = shift @_;  #  Path to source file.
    my $dPath = shift @_;  #  Path to destination file.

    if ((-e $sPath) &&
        ((! -e $dPath) ||
         ((-M $sPath) < (-M $dPath)))) {
        copy($sPath, $dPath);
    }
}



sub simpleFigure ($$$$) {
    my $body   = shift @_;
    my $sImage = shift @_;
    my $dImage = shift @_;
    my $text   = shift @_;
    my $format = getGlobal("gnuplotImageFormat");

    #  No image?  Note so in the html.

    if ((! -e "$sImage.sm.$format") && (! -e "$sImage.lg.$format") &&
        (! -e "$dImage.sm.$format") && (! -e "$dImage.lg.$format")) {
        push @$body, "<p>Image '$sImage' not found.</p>\n";
        return;
    }

    #  Copy the file to our files location.

    copyFile("$sImage.lg.$format", "$dImage.lg.$format");
    copyFile("$sImage.sm.$format", "$dImage.sm.$format");

    #  Empty image?  Note so in the html.

    if ((-z "$dImage.sm.$format") || (-z "$dImage.lg.$format")) {
        push @$body, "<p>Image '$sImage' is empty.  Probably no data to display.</p>\n";
        return;
    }

    #  Otherwise, show it!

    push @$body, "<figure>\n";
    push @$body, "<a href='$dImage.lg.$format'><img src='$dImage.sm.$format'></a>\n";
    push @$body, "<figcaption>\n";
    push @$body, "$text\n";
    push @$body, "</figcaption>\n";
    push @$body, "</figure>\n";
}



sub buildGatekeeperHTML ($$$$$$) {
    my $wrk     = shift @_;
    my $asm     = shift @_;
    my $tag     = shift @_;
    my $css     = shift @_;  #  Array reference
    my $body    = shift @_;  #  Array reference
    my $scripts = shift @_;  #  Array reference

    push @$body, "<h2>Input Reads</h2>\n";
    push @$body, "\n";

    if (! -e "$wrk/$asm.gkpStore/load.dat") {
        push @$body, "<p>None loaded.</p>\n";
        return;
    }

    push @$body, "<table>\n";

    open(F, "< $wrk/$asm.gkpStore/load.dat") or caExit("can't open '$wrk/$asm.gkpStore/load.dat' for reading: $!", undef);
    while (<F>) {

        #  nam blocks show up once per file.
        if (m/^nam\s(\d+)\s(.*)$/) {
            my $idx  = $1;
            my $file = $2;

            push @$body, "<tr id='gkpload$idx'><td colspan='2'>$file</td></tr>\n";

            push @$scripts, "document.getElementById('gkpload$idx').onclick = toggleTable;\n";
            push @$scripts, "document.getElementById('gkpload$idx').style   = 'cursor: pointer;';\n";
        }

        #  lib blocks show up once per file, all paramters are on the same line
        elsif (m/^lib\s/) {
            my @libs = split '\s+', $_;
            my ($param, $np, $var, $val);

            $param = shift @libs;  #  Throw out the first 'lib' word.
            $np    = scalar(@libs);
            $param = shift @libs;  #  First thing we want to report.

            #  First row needs to have a spanning cell for the 'parameters'.
            ($var, $val) = split '=', $param;
            push @$body, "<tr class='details'><td rowspan='$np'>Parameters</td><td>$var = $val</td></tr>\n";

            #  Remaining rows just have var=val.
            foreach $param (@libs) {
                ($var, $val) = split '=', $param;
                push @$body, "<tr class='details'><td>$var = $val</td></tr>\n";
            }
        }

        #  dat blocks show up once per file, and are the last block emitted for a file
        elsif (m/^dat\s(\d+)\s(\d+)\s(\d+)\s(\d+)\s(\d+)\s(\d+)\s(\d+)\s(\d+)\s(\d+)$/) {
            my $nLOADEDA  = $1;
            my $bLOADEDA  = $2;
            my $nSKIPPEDA = $3;
            my $bSKIPPEDA = $4;
            my $nLOADEDQ  = $5;
            my $bLOADEDQ  = $6;
            my $nSKIPPEDQ = $7;
            my $bSKIPPEDQ = $8;
            my $nWARNS    = $9;

            push @$body, "<tr class='details'><td rowspan='2'>FASTA</td><td>$nLOADEDA reads ($bLOADEDA bp)</td></tr>\n",;
            push @$body, "<tr class='details'><td>$nSKIPPEDA reads ($bSKIPPEDA bp) were short and not loaded</td></tr>\n";

            push @$body, "<tr class='details'><td rowspan='2'>FASTQ</td><td>$nLOADEDQ reads ($bLOADEDQ bp)</td></tr>\n";
            push @$body, "<tr class='details'><td>$nSKIPPEDQ reads ($bSKIPPEDQ bp) were short and not loaded</td></tr>\n";

            my $nl = $nLOADEDA  + $nLOADEDQ;
            my $bl = $bLOADEDA  + $bLOADEDQ;
            my $ns = $nSKIPPEDA + $nSKIPPEDQ;
            my $bs = $bSKIPPEDA + $bSKIPPEDQ;

            push @$body, "<tr><td colspan='2'>$nl reads ($bl bp) loaded, $ns reads ($bs bp) skipped, $nWARNS warnings</td></tr>\n";
        }

        #  the sum block shows up excatly once, a summary of all the reads loaded
        elsif (m/^sum\s(\d+)\s(\d+)\s(\d+)\s(\d+)\s(\d+)$/) {
            my $nLOADED  = $1;
            my $bLOADED  = $2;
            my $nSKIPPED = $3;
            my $bSKIPPED = $4;
            my $nWARNS   = $5;

            push @$body, "</table>\n";
            push @$body, "\n";
            push @$body, "<h2>Final Store</h2>\n";
            push @$body, "\n";
            push @$body, "<table>\n";
            push @$body, "<tr><td colspan='2'>$wrk/$asm.gkpStore</td></tr>\n";
            push @$body, "<tr><td>readsLoaded</td><td>$nLOADED reads ($bLOADED bp)</td></tr>\n";
            push @$body, "<tr><td>readsSkipped</td><td>$nSKIPPED reads ($bSKIPPED bp) (read was too short)</td></tr>\n";
            push @$body, "<tr><td>warnings</td><td>$nWARNS warnings (invalid base or quality value)</td></tr>\n";
            push @$body, "</table>\n";

        } else {
            caExit("failed to read '$wrk/$asm.gkpStore/load.log': invalid format", undef);
        }
    }
    close(F);

    push @$body, "<h3>Read Length Histogram</h3>\n";
    simpleFigure($body,
                 "$wrk/$asm.gkpStore/readlengths",
                 "$wrk.html.files/readlengths",
                 "");
}


sub buildMerylHTML ($$$$$$) {
    my $wrk     = shift @_;
    my $asm     = shift @_;
    my $tag     = shift @_;
    my $css     = shift @_;  #  Array reference
    my $body    = shift @_;  #  Array reference
    my $scripts = shift @_;  #  Array reference

    push @$body, "<h2>k-Mer Counts</h2>\n";
    push @$body, "\n";

    if (! -d "$wrk/0-mercounts") {
        push @$body, "<p>Stage not computed. ($wrk/0-mercounts)</p>\n";
        return;
    }

    my %merSizes;

    open(F, "ls $wrk/0-mercounts/ |") or caExit("can't find files in '$wrk/0-mercounts': $!", undef);
    while (<F>) {
        if (m/\.ms(\d+)\./) {
            $merSizes{$1}++;
        }
    }
    close(F);

    foreach my $ms (keys %merSizes) {
        my $numTotal    = 0;
        my $numDistinct = 0;
        my $numUnique   = 0;
        my $largest     = 0;

        if (-e "$wrk/0-mercounts/$asm.ms$ms.histogram.info") {
            open(F, "<  $wrk/0-mercounts/$asm.ms$ms.histogram.info") or caExit("can't open '$wrk/0-mercounts/$asm.ms$ms.histogram.info' for reading: $!", undef);
            while (<F>) {
                $numTotal    = $1   if (m/Found\s(\d+)\s+mers./);
                $numDistinct = $1   if (m/Found\s(\d+)\s+distinct\smers./);
                $numUnique   = $1   if (m/Found\s(\d+)\s+unique\smers./);
                $largest     = $1   if (m/Largest\smercount\sis\s(\d+)/);
            }
            close(F);

            simpleFigure($body,
                         "$wrk/0-mercounts/$asm.ms$ms.histogram",
                         "$wrk.html.files/$asm.ms$ms.histogram",
                         "Histogram for k=$ms with $numTotal mers, $numDistinct distinct mers and $numUnique single-copy mers.  Largest count is $largest.");
        }

        elsif ((-e "$wrk/0-mercounts/$asm.ms$ms.ignore") && (-z "$wrk/0-mercounts/$asm.ms$ms.ignore")) {
            push @$body, "Threshold zero.  No mers reported.\n";
        }

        elsif ((-e "$wrk/0-mercounts/$asm.ms$ms.fasta")  && (-z "$wrk/0-mercounts/$asm.ms$ms.fasta")) {
            push @$body, "Threshold zero.  No mers reported.\n";
        }

        else {
            push @$body, "Using user-supplied frequent mers.\n";
        }
    }
}



sub buildCorrectionHTML ($$$$$$) {
    my $wrk     = shift @_;
    my $asm     = shift @_;
    my $tag     = shift @_;
    my $css     = shift @_;  #  Array reference
    my $body    = shift @_;  #  Array reference
    my $scripts = shift @_;  #  Array reference


    #  Need to include the minimum original read length that is correctable


    #  Summarizes filterCorrectionOverlaps outputs.

    push @$body, "<h2>Overlap Filtering</h2>\n";
    push @$body, "\n";

    if (-e "$wrk/2-correction/$asm.globalScores.stats") {
        my $rh;   # 'row header', for labeling a set of rows with a common cell

        push @$body, "<table>\n";

        open(F, "< $wrk/2-correction/$asm.globalScores.stats") or caExit("can't open '$wrk/2-correction/$asm.globalScores.stats' for reading: $!", undef);
        while (<F>) {
            chomp;

            next  if (m/^$/);  #  Skip blank lines.

            push @$body, "<tr><th colspan='3'>PARAMETERS</th></tr>\n"  if ($_ eq "PARAMETERS:");
            push @$body, "<tr><th colspan='3'>OVERLAPS</th></tr>\n"    if ($_ eq "OVERLAPS:");
            push @$body, "<tr><th colspan='3'>READS</th></tr>\n"       if ($_ eq "READS:");

            $rh = "<td rowspan='4'></td>"             if ($_ eq "PARAMETERS:");
            $rh = "<td rowspan='4'></td>"             if ($_ eq "OVERLAPS:");     #  Gets replaced by 'IGNORED' below.
            $rh = "<td rowspan='6'></td>"             if ($_ eq "READS:");

            $rh = "<td rowspan='4'>Ignored</td>"      if ($_ eq "IGNORED:");
            $rh = "<td rowspan='1'>Filtered</td>"     if ($_ eq "FILTERED:");
            $rh = "<td rowspan='1'>Evidence</td>"     if ($_ eq "EVIDENCE:");
            $rh = "<td rowspan='1'>Total</td>"        if ($_ eq "TOTAL:");

            if (m/^\s*(\d+\.*\d*)\s+\((.*)\)$/) {
                push @$body, "<tr>$rh<td>$1</td><td>$2</td></tr>\n";
                $rh = undef;
            }
        }
        close(F);

        push @$body, "</table>\n";

    } else {
        push @$body, "<p>Stage not computed or results file removed ($wrk/2-correction/$asm.globalScores.stats).</p>\n";
    }


    push @$body, "<h2>Read Correction</h2>\n";
    push @$body, "\n";


    #  Summarizes expensiveFilter() outputs - we want to get the 'corrected read length filter' numbers.
    #  which should be the first set in the file.

    my $nReads    = undef;
    my $nBasesIn  = undef;
    my $nBasesOut = undef;

    if (-e "$wrk/2-correction/$asm.readsToCorrect.summary") {
        open(F, "< $wrk/2-correction/$asm.readsToCorrect.summary") or caExit("can't open '$wrk/2-correction/$asm.readsToCorrect.summary' for reading: $!", undef);
        while (<F>) {
            $nReads    = $1  if ((m/nReads\s+(\d+)/)         && (!defined($nReads)));
            $nBasesIn  = $1  if ((m/nBasds\s+(\d+).*input/)  && (!defined($nBasesIn)));
            $nBasesOut = $1  if ((m/nReads\s+(\d+).*output/) && (!defined($nBasesOut)));

            last             if (m/^Raw\sreads/);
        }
        close(F);

        push @$body, "<p>Filter method: corFilter=expensive.  Expect to correct $nReads reads with ${nBasesIn}bp to ${nBasesOut}bp.</p>\n";
    } else {
        push @$body, "<p>Filter method: corFilter=quick.</p>\n";
    }


    #  $wrk/2-correction/$asm.readsToCorrect has 'readID', 'originalLength' and 'expectedCorrectedLength'.
    #  $WRK/$asm.correctedReads.length has 'readID', 'pieceID', 'length'.
    #
    #  Both files should be sorted by increasing ID, so a simple merge sufficies.

    if (-e "$wrk/2-correction/$asm.correction.summary") {
        my $rh;

        push @$body, "<table>\n";

        open(F, "< $wrk/2-correction/$asm.correction.summary") or caExit("can't open '$wrk/2-correction/$asm.correction.summary' for reading: $!", undef);
        while (<F>) {
            chomp;

            next  if (m/^$/);  #  Skip blank lines.

            push @$body, "<tr><th colspan='3'>INPUTS</th></tr>\n"            if ($_ eq "CORRECTION INPUTS:");
            push @$body, "<tr><th colspan='3'>OUTPUTS</th></tr>\n"           if ($_ eq "CORRECTION OUTPUTS:");
            push @$body, "<tr><th colspan='3'>PIECES PER READ</th></tr>\n"   if ($_ eq "PIECES PER READ:");

            #  Normal table lines.
            if (m/^\s*(\d+\.*\d*)\s+\((.*)\)$/) {
                push @$body, "<tr>$rh<td>$1</td><td>$2</td></tr>\n";
                $rh = undef;
            }

            #  Pieces per read histogram.
            if (m/^\s*(\d+)\s+pieces:\s+(\d+)$/) {
                push @$body, "<tr>$rh<td>$1</td><td>$2</td></tr>\n";
                $rh = undef;
            }
        }
        close(F);

        push @$body, "</table>\n";
    }

    #  Really should be a 'caption' on the 'pieces per read' table.
    push @$body, "<p>A single input read can be split into multiple output reads, or possibly not even output at all.</p>\n";

    #  Simple vs Expensive filter true/false positive

    simpleFigure($body,
                 "$wrk/2-correction/$asm.estimate.original-x-corrected",
                 "$wrk.html.files/$asm.estimate.original-x-corrected",
                 "Scatter plot of the original read length (X axis) against the expected corrected read length (Y axis).\n" .
                 "Colors show a comparison of the simple filter (which doesn't use overlaps) to the expensive filter (which does).\n" .
                 "A large green triangle (false negatives) hints that there could be abnormally low quality regions in the reads.\n");

    #  Scatter plots of read lengths - they don't show much.

    #  Original vs expected shown above.
    simpleFigure($body,
                 "$wrk/2-correction/$asm.originalLength-vs-expectedLength",
                 "$wrk.html.files/$asm.originalLength-vs-expectedLength",
                 "Scatter plot of original vs expected read length.  Shown in filter plot above.");

    simpleFigure($body,
                 "$wrk/2-correction/$asm.originalLength-vs-correctedLength",
                 "$wrk.html.files/$asm.originalLength-vs-correctedLength",
                 "Scatter plot of original vs corrected read length.");

    simpleFigure($body,
                 "$wrk/2-correction/$asm.expectedLength-vs-correctedLength",
                 "$wrk.html.files/$asm.expectedLength-vs-correctedLength",
                 "Scatter plot of expected vs corrected read length.");

    #  Histogram - expected vs corrected lengths NEEDS TO SHOW NEGATIVES!?

    simpleFigure($body,
                 "$wrk/2-correction/$asm.length-difference-histograms",
                 "$wrk.html.files/$asm.length-difference-histograms",
                 "Histogram of the difference between the expected and corrected read lengths.\n" .
                 "Note that a negative difference means the corrected read is larger than expected.\n");

    #  Histogram - original, expected, corrected lengths

    simpleFigure($body,
                 "$wrk/2-correction/$asm.length-histograms",
                 "$wrk.html.files/$asm.length-histograms",
                 "Histogram of original (red), expected (green) and actual corrected (blue) read lengths.\n");
}




sub buildTrimmingHTML ($$$$$$) {
    my $wrk     = shift @_;
    my $asm     = shift @_;
    my $tag     = shift @_;
    my $css     = shift @_;  #  Array reference
    my $body    = shift @_;  #  Array reference
    my $scripts = shift @_;  #  Array reference

    push @$body, "<h2>Trimming</h2>\n";
    push @$body, "\n";


    if (-e "$wrk/3-overlapbasedtrimming/$asm.1.trimReads.stats") {
        my $rh;   # 'row header', for labeling a set of rows with a common cell

        #  Read once to make a paramters table.  We could have embedded this in the loop below, but it's cleaner here.

        #push @$body, "<table>\n";
        #push @$body, "</table>\n";

        #  Read again for the statistics.

        push @$body, "<table>\n";

        open(F, "< $wrk/3-overlapbasedtrimming/$asm.1.trimReads.stats") or caExit("can't open '$wrk/3-overlapbasedtrimming/$asm.1.trimReads.stats' for reading: $!", undef);
        while (<F>) {
            chomp;

            next  if (m/^$/);  #  Skip blank lines.

            push @$body, "<tr><th colspan='2'>PARAMETERS</th></tr>\n"        if ($_ eq "PARAMETERS:");

            push @$body, "</table>\n"                                        if ($_ eq "INPUT READS:");  #  Start a new table because 'params' has only
            push @$body, "<table>\n"                                         if ($_ eq "INPUT READS:");  #  2 cols, but the rest have 3
            push @$body, "<tr><th colspan='3'>INPUT READS</th></tr>\n"       if ($_ eq "INPUT READS:");
            push @$body, "<tr><th>reads</th><th>bases</th><th></th></tr>\n"  if ($_ eq "INPUT READS:");

            push @$body, "<tr><th colspan='3'>OUTPUT READS</th></tr>\n"      if ($_ eq "OUTPUT READS:");
            push @$body, "<tr><th>reads</th><th>bases</th><th></th></tr>\n"  if ($_ eq "OUTPUT READS:");

            push @$body, "<tr><th colspan='3'>TRIMMING DETAILS</th></tr>\n"  if ($_ eq "TRIMMING DETAILS:");
            push @$body, "<tr><th>reads</th><th>bases</th><th></th></tr>\n"  if ($_ eq "TRIMMING DETAILS:");

            #  Normal stats line "number (text)"
            if (m/^\s*(\d+\.*\d*)\s+\((.*)\)$/) {
                push @$body, "<tr>$rh<td>$1</td><td>$2</td></tr>\n";
                $rh = undef;
            }

            #  Specific to trimming "number reads number bases (text)"
            if (m/^\s*(\d+\.*\d*)\s+reads\s+(\d+\.*\d*)\s+bases\s+\((.*)\)$/) {
                push @$body, "<tr>$rh<td>$1</td><td>$2</td><td>$3</td></tr>\n";
                $rh = undef;
            }
        }
        close(F);

        push @$body, "</table>\n";

    } else {
        push @$body, "<p>Stage not computed or results file removed ($wrk/3-overlapbasedtrimming/$asm.1.trimReads.stats).</p>\n";
    }

    simpleFigure($body, "$wrk/3-overlapbasedtrimming/$asm.1.trimReads.inputDeletedReads",    "$wrk.html.files/$asm.1.trimReads.inputDeletedReads",    "");
    simpleFigure($body, "$wrk/3-overlapbasedtrimming/$asm.1.trimReads.inputNoTrimReads",     "$wrk.html.files/$asm.1.trimReads.inputNoTrimReads",     "");
    simpleFigure($body, "$wrk/3-overlapbasedtrimming/$asm.1.trimReads.inputReads",           "$wrk.html.files/$asm.1.trimReads.inputReads",           "");
    simpleFigure($body, "$wrk/3-overlapbasedtrimming/$asm.1.trimReads.outputDeletedReads",   "$wrk.html.files/$asm.1.trimReads.outputDeletedReads",   "");
    simpleFigure($body, "$wrk/3-overlapbasedtrimming/$asm.1.trimReads.outputNoOvlReads",     "$wrk.html.files/$asm.1.trimReads.outputNoOvlReads",     "");
    simpleFigure($body, "$wrk/3-overlapbasedtrimming/$asm.1.trimReads.outputTrimmedReads",   "$wrk.html.files/$asm.1.trimReads.outputTrimmedReads",   "");
    simpleFigure($body, "$wrk/3-overlapbasedtrimming/$asm.1.trimReads.outputUnchangedReads", "$wrk.html.files/$asm.1.trimReads.outputUnchangedReads", "");
    simpleFigure($body, "$wrk/3-overlapbasedtrimming/$asm.1.trimReads.trim3",                "$wrk.html.files/$asm.1.trimReads.trim3",                "");
    simpleFigure($body, "$wrk/3-overlapbasedtrimming/$asm.1.trimReads.trim5",                "$wrk.html.files/$asm.1.trimReads.trim5",                "");

    push @$body, "<h2>Splitting</h2>\n";
    push @$body, "\n";

    if (-e "$wrk/3-overlapbasedtrimming/$asm.2.splitReads.stats") {
        my $rh;   # 'row header', for labeling a set of rows with a common cell

        #  Read once to make a paramters table.  We could have embedded this in the loop below, but it's cleaner here.

        #push @$body, "<table>\n";
        #push @$body, "</table>\n";

        #  Read again for the statistics.

        push @$body, "<table>\n";

        open(F, "< $wrk/3-overlapbasedtrimming/$asm.2.splitReads.stats") or caExit("can't open '$wrk/3-overlapbasedtrimming/$asm.2.splitReads.stats' for reading: $!", undef);
        while (<F>) {
            chomp;

            next  if (m/^$/);  #  Skip blank lines.

            push @$body, "<tr><th colspan='2'>PARAMETERS</th></tr>\n"        if ($_ eq "PARAMETERS:");

            push @$body, "</table>\n"                                        if ($_ eq "INPUT READS:");  #  Start a new table because 'params' has only
            push @$body, "<table>\n"                                         if ($_ eq "INPUT READS:");  #  2 cols, but the rest have 3
            push @$body, "<tr><th colspan='3'>INPUT READS</th></tr>\n"         if ($_ eq "INPUT READS:");
            push @$body, "<tr><th>reads</th><th>bases</th><th></th></tr>\n"    if ($_ eq "INPUT READS:");

            push @$body, "<tr><th colspan='3'>PROCESSED</th></tr>\n"           if ($_ eq "PROCESSED:");
            push @$body, "<tr><th>reads</th><th>bases</th><th></th></tr>\n"    if ($_ eq "PROCESSED:");

            push @$body, "<tr><th colspan='3'>READS WITH SIGNALS</th></tr>\n"  if ($_ eq "READS WITH SIGNALS:");
            push @$body, "<tr><th>reads</th><th>signals</th><th></th></tr>\n"  if ($_ eq "READS WITH SIGNALS:");

            push @$body, "<tr><th colspan='3'>SIGNALS</th></tr>\n"             if ($_ eq "SIGNALS:");
            push @$body, "<tr><th>reads</th><th>bases</th><th></th></tr>\n"    if ($_ eq "SIGNALS:");

            push @$body, "<tr><th colspan='3'>TRIMMING</th></tr>\n"            if ($_ eq "TRIMMING:");
            push @$body, "<tr><th>reads</th><th>bases</th><th></th></tr>\n"    if ($_ eq "TRIMMING:");

            #  Normal stats line "number (text)"
            if (m/^\s*(\d+\.*\d*)\s+\((.*)\)$/) {
                push @$body, "<tr>$rh<td>$1</td><td>$2</td></tr>\n";
                $rh = undef;
            }

            #  Specific to trimming "number reads number bases (text)"
            if (m/^\s*(\d+\.*\d*)\s+reads\s+(\d+\.*\d*)\s+bases\s+\((.*)\)$/) {
                push @$body, "<tr>$rh<td>$1</td><td>$2</td><td>$3</td></tr>\n";
                $rh = undef;
            }
            if (m/^\s*(\d+\.*\d*)\s+reads\s+(\d+\.*\d*)\s+signals\s+\((.*)\)$/) {
                push @$body, "<tr>$rh<td>$1</td><td>$2</td><td>$3</td></tr>\n";
                $rh = undef;
            }
        }
        close(F);

        push @$body, "</table>\n";

    } else {
        push @$body, "<p>Stage not computed or results file removed ($wrk/3-overlapbasedtrimming/$asm.2.splitReads.stats).</p>\n";
    }


    #buildGatekeeperHTML($wrk, $asm, $tag, $css, $body, $scripts);
    #  Analyzes the output fastq
}




sub buildOverlapperHTML ($$$$$$) {
    my $wrk     = shift @_;
    my $asm     = shift @_;
    my $tag     = shift @_;
    my $css     = shift @_;  #  Array reference
    my $body    = shift @_;  #  Array reference
    my $scripts = shift @_;  #  Array reference

    push @$body, "<h2>Overlaps</h2>\n";
    push @$body, "\n";

    if (! -d "$wrk/$asm.ovlStore") {
        push @$body, "<p>Overlaps not computed.</p>\n";
        return;
    }

    if (! -e "$wrk/$asm.ovlStore.summary") {
        push @$body, "<p>No statistics available for store '$wrk/$asm.ovlStore'.</p>\n";
        return;
    }

    push @$body, "<table>\n";
    push @$body, "<tr><th>Category</th><th>Reads</th><th>%</th><th colspan='3'>Read Length</th><th colspan='3'>Feature Size or Coverage</th><th>Analysis</th></tr>\n";

    my ($category, $reads, $readsP, $length, $lengthsd, $size, $sizesd, $analysis);

    open(F, "< $wrk/$asm.ovlStore.summary") or caExit("Failed to open overlap store statistics in '$wrk/$asm.ovlStore': $!", undef);
    $_ = <F>;
    $_ = <F>;
    while (<F>) {
        chomp;

        next if ($_ eq "");

        if      (m/(.*)\s+(\d+)\s+(\d+.\d+)\s+(\d+.\d+)\s+\+-\s+(\d+.\d+)\s+(\d+.\d+)\s+\+-\s+(\d+.\d+)\s+\((.*)\)$/) {
            $category = $1;
            $reads    = $2;
            $readsP   = $3;
            $length   = $4;
            $lengthsd = $5;
            $size     = $6;
            $sizesd   = $7;
            $analysis = $8;
            push @$body, "<tr><td>$category</td><td>$reads</td><td>$readsP</td><td align='right'>$length</td><td>&plusmn;</td><td align='left'>$lengthsd</td><td align='right'>$size</td><td>&plusmn;</td><td align='left'>$sizesd</td><td align='left'>$analysis</td></tr>\n";

        } elsif (m/(.*)\s+(\d+)\s+(\d+.\d+)\s+(\d+.\d+)\s+\+-\s+(\d+.\d+)\s+\((.*)\)$/) {
            $category = $1;
            $reads    = $2;
            $readsP   = $3;
            $length   = $4;
            $lengthsd = $5;
            $size     = undef;
            $sizesd   = undef;
            $analysis = $6;
            push @$body, "<tr><td>$category</td><td>$reads</td><td>$readsP</td><td align='right'>$length</td><td>&plusmn;</td><td align-'left'>$lengthsd</td><td></td><td></td><td></td><td align='left'>$analysis</td></tr>\n";

        } else {
            chomp;
            caExit("failed to parse line '$_' in file '$wrk/$asm.ovlStore.summary'", undef);
        }
    }
    close(F);

    push @$body, "</table>\n";
}


sub buildOverlapErrorCorrectionHTML ($$$$$$) {
    my $wrk     = shift @_;
    my $asm     = shift @_;
    my $tag     = shift @_;
    my $css     = shift @_;  #  Array reference
    my $body    = shift @_;  #  Array reference
    my $scripts = shift @_;  #  Array reference

    push @$body, "<h2>Overlap Error Adjustment</h2>\n";
    push @$body, "\n";
}



sub reportSizeStatistics ($$$) {
    my $css     = shift @_;  #  Array reference
    my $body    = shift @_;  #  Array reference
    my $scripts = shift @_;  #  Array reference

    $_ = <F>;  chomp;  #  First real line.

    push @$body, "<table>\n";
    push @$body, "<tr><th>Fraction</th><th>Length</th><th>Sequences</th><th>Bases</th></tr>\n";

    while (!eof(F) && (length($_) > 0)) {
        if (m/^(\w+)\s+\((\d+)\s+tigs\)\s+\((\d+)\s+length\)\s+\((\d+)\s+average\)\s+\((\d+.\d+x)\s+coverage\)$/) {
            push @$body, "<tr><td colspan='5'>$_</td></tr>\n";
        }

        if (m/^ng(\d\d\d)\s+(\d+)\s+lg(\d\d\d)\s+(\d+)\s+sum\s+(\d+)\s+\((\w+\))$/) {
            my $ng  = $1;
            my $ngv = $2;
            my $lg  = $3;
            my $lgv = $4;
            my $sum = $5;
            my $typ = $6;

            $ng =~ s/^0*//;

            push @$body, "<tr><td>$ng</td><td>$ngv</td><td>$lgv</td><td>$sum</td></tr>\n";
        }

        $_ = <F>;  chomp;
    }

    push @$body, "</table>\n";
}


sub buildUnitiggerHTML ($$$$$$) {
    my $wrk     = shift @_;
    my $asm     = shift @_;
    my $tag     = shift @_;
    my $css     = shift @_;  #  Array reference
    my $body    = shift @_;  #  Array reference
    my $scripts = shift @_;  #  Array reference

    return  if (! -d "$wrk/4-unitigger");

    my @logs;

    push @logs, "$wrk/4-unitigger/unitigger.err";

    open(F, "ls $wrk/4-unitigger |");
    while (<F>) {
        chomp;

        push @logs, "$wrk/4-unitigger/$_"   if (m/log$/);
    }
    close(F);

    push @$body, "<h2>Unitigs</h2>\n";
    push @$body, "\n";

    if (-e "$wrk/4-unitigger/unitigger.err") {
        my $all   = 0;
        my $some  = 0;
        my $someL = 0;
        my $olaps = 0;

        open(F, "< $wrk/4-unitigger/unitigger.err");
        while (<F>) {
            chomp;

            #if (m/maxPer.*numBelow=(\d+)\snumEqual=(\d+)\snumAbove=(\d+)\stotalLoad=(\d+)\s/) {
            #    push @$body, "Loaded $4 overlaps.  $3 overlaps were omitted due to memory constraints.\n";
            #}

            $someL  = $1   if (m/_maxPer\s+=\s+(\d+)\s+overlaps/);
            $all   += $1   if (m/numBelow\s+=\s+(\d+)\s+reads/);
            $all   += $1   if (m/numEqual\s+=\s+(\d+)\s+reads/);
            $some   = $1   if (m/numAbove\s+=\s+(\d+)\s+reads/);
            $olaps  = $1   if (m/totalLoad\s+=\s+(\d+)\s+overlaps/);


        }
        close(F);

        push @$body, "<h3>Overlaps</h3>\n";
        push @$body, "\n";
        push @$body, "Loaded all overlaps for $all reads.<br>\n";
        push @$body, "Loaded some overlaps for $some reads (the best $someL for each read).<br>\n"  if ($some > 0);
        push @$body, "Loaded $olaps overlaps in total.<br>\n";
    }

    if (-e "$wrk/4-unitigger/$asm.001.filterOverlaps.thr000.num000.log") {
        push @$body, "<h3>Edges</h3>\n";
        push @$body, "\n";

        my $initContained      = 0;
        my $initSingleton      = 0;
        my $initSpur           = 0;
        my $initSpurMutualBest = 0;
        my $initBest           = 0;
        my $initBest0Mutual    = 0;
        my $initBest1Mutual    = 0;
        my $initBest2Mutual    = 0;

        my $mean   = 0;  my $stddev  = 0;  my $ms         = 0;
        my $median = 0;  my $mad     = 0;  my $mm         = 0;
        my $noBest = 0;  my $highErr = 0;  my $acceptable = 0;

        my $suspicious  = 0;
        my $filtered1   = 0;
        my $filtered2   = 0;
        my $lopsided1   = 0;
        my $lopsided2   = 0;

        my $finalContained      = 0;
        my $finalSingleton      = 0;
        my $finalSpur           = 0;
        my $finalSpurMutualBest = 0;
        my $finalBest           = 0;
        my $finalBest0Mutual    = 0;
        my $finalBest1Mutual    = 0;
        my $finalBest2Mutual    = 0;

        open(F, "$wrk/4-unitigger/$asm.001.filterOverlaps.thr000.num000.log");
        $_ = <F>;  chomp;

        my $block = "none";

        while (!eof(F)) {
            $block = "init"   if (m/^INITIAL\sEDGES/);
            $block = "error"  if (m/^ERROR\sRATES/);
            $block = "edge"   if (m/^EDGE\sFILTERING/);
            $block = "final"  if (m/^FINAL\sEDGES/);

            $initContained      = $1    if (($block eq "init") && (m/(\d+)\sreads\sare\scontained/));
            $initSingleton      = $1    if (($block eq "init") && (m/(\d+)\sreads\shave\sno\sbest\sedges/));
            $initSpur           = $1    if (($block eq "init") && (m/(\d+)\sreads\shave\sonly\sone\sbest\sedge.*spur/));
            $initSpurMutualBest = $1    if (($block eq "init") && (m/(\d+)\sare\smutual\sbest/));
            $initBest           = $1    if (($block eq "init") && (m/(\d+)\sreads\shave\stwo\sbest\sedges/));
            $initBest1Mutual    = $1    if (($block eq "init") && (m/(\d+)\shave\sone\smutual\sbest/));
            $initBest2Mutual    = $1    if (($block eq "init") && (m/(\d+)\shave\stwo\smutual\sbest/));

            if (($block eq "error") && (m/mean\s+(\d+.\d+)\s+stddev\s+(\d+.\d+)\s+.*\s+(\d+.\d+)\s+fraction\serror/)) {
                $mean   = $1;
                $stddev = $2;
                $ms     = $3;
            }
            if (($block eq "error") && (m/median\s+(\d+.\d+)\s+mad\s+(\d+.\d+)\s+.*\s+(\d+.\d+)\s+fraction\serror/)) {
                $median = $1;
                $mad    = $2;
                $mm     = $3;
            }

            $suspicious   = $1   if (($block eq "edge") && (m/(\d+)\sreads\shave\sa\ssuspicious\soverlap\spattern/));
            $filtered1    = $1   if (($block eq "edge") && (m/(\d+)\shad\sone/));
            $filtered2    = $1   if (($block eq "edge") && (m/(\d+)\shad\stwo/));
            $lopsided1    = $1   if (($block eq "edge") && (m/(\d+)\shave\sone/));
            $lopsided2    = $1   if (($block eq "edge") && (m/(\d+)\shave\stwo/));

            $finalContained      = $1    if (($block eq "final") && (m/(\d+)\sreads\sare\scontained/));
            $finalSingleton      = $1    if (($block eq "final") && (m/(\d+)\sreads\shave\sno\sbest\sedges/));
            $finalSpur           = $1    if (($block eq "final") && (m/(\d+)\sreads\shave\sonly\sone\sbest\sedge.*spur/));
            $finalSpurMutualBest = $1    if (($block eq "final") && (m/(\d+)\sare\smutual\sbest/));
            $finalBest           = $1    if (($block eq "final") && (m/(\d+)\sreads\shave\stwo\sbest\sedges/));
            $finalBest1Mutual    = $1    if (($block eq "final") && (m/(\d+)\shave\sone\smutual\sbest/));
            $finalBest2Mutual    = $1    if (($block eq "final") && (m/(\d+)\shave\stwo\smutual\sbest/));

            $_ = <F>;  chomp;
        }

        close(F);

        $initBest0Mutual  = $initBest  - $initBest1Mutual  - $initBest2Mutual;
        $finalBest0Mutual = $finalBest - $finalBest1Mutual - $finalBest2Mutual;

        push @$body, "Constructing unitigs using overlaps of at most this fraction error:<br>\n";
        push @$body, "$median +- $mad = $mm = ", $mm * 100, "\% (median absolute deviation)<br>\n";
        push @$body, "$mean +- $stddev = $ms = ", $ms * 100, "\% (standard deviation)<br>\n";
        push @$body, "<br>\n";
        push @$body, "INITIAL EDGES<br>\n";
        push @$body, "$initContained reads are contained.<br>\n";
        push @$body, "$initSingleton reads are singleton.<br>\n";
        push @$body, "$initSpur reads are spur ($initSpurMutualBest have a mutual best edge).<br>\n";
        push @$body, "$initBest reads form the backbone ($initBest0Mutual have no mutual best edges; $initBest1Mutual have one; $initBest2Mutual have both).<br>\n";
        push @$body, "<br>\n";
        push @$body, "FILTERING<br>\n";
        push @$body, "$suspicious reads have a suspicious overlap pattern.<br>\n";
        push @$body, "$filtered1 had one high error rate edge filtered; $filtered2 had both.<br>\n";
        push @$body, "$lopsided1 had one size incompatible edge filtered; $lopsided2 had both.<br>\n";
        push @$body, "<br>\n";
        push @$body, "FINAL EDGES<br>\n";
        push @$body, "$finalContained reads are contained.<br>\n";
        push @$body, "$finalSingleton reads are singleton.<br>\n";
        push @$body, "$finalSpur reads are spur ($finalSpurMutualBest have a mutual best edge).<br>\n";
        push @$body, "$finalBest reads form the backbone ($finalBest0Mutual have no mutual best edges; $finalBest1Mutual have one; $finalBest2Mutual have both).<br>\n";
    }


    push @$body, "<h3>Initial Tig Sizes</h3>\n";

    if (-e "$wrk/4-unitigger/$asm.003.buildUnitigs.sizes") {
        open(F, "< $wrk/4-unitigger/$asm.003.buildUnitigs.sizes");
        reportSizeStatistics($css, $body, $scripts);
        close(F);
    }

    push @$body, "<h3>Final Tig Sizes</h3>\n";

    if (-e "$wrk/4-unitigger/$asm.008.generateOutputs.sizes") {
        open(F, "< $wrk/4-unitigger/$asm.008.generateOutputs.sizes");
        reportSizeStatistics($css, $body, $scripts);
        close(F);
    }

}



sub buildConsensusHTML ($$$$$$) {
    my $wrk     = shift @_;
    my $asm     = shift @_;
    my $tag     = shift @_;
    my $css     = shift @_;  #  Array reference
    my $body    = shift @_;  #  Array reference
    my $scripts = shift @_;  #  Array reference

    push @$body, "<h2>Consensus</h2>\n";
    push @$body, "\n";
}


sub buildOutputHTML ($$$$$$) {
    my $wrk     = shift @_;
    my $asm     = shift @_;
    my $tag     = shift @_;
    my $css     = shift @_;  #  Array reference
    my $body    = shift @_;  #  Array reference
    my $scripts = shift @_;  #  Array reference

    push @$body, "<h2>Final Outputs</h2>\n";
    push @$body, "\n";
}


sub buildHTML ($$$) {
    my $WRK     = shift @_;  #  Root work directory (the -d option to canu)
    my $wrk     = $WRK;      #  Local work directory
    my $asm     = shift @_;
    my $tag     = shift @_;
    my @css;
    my @body;
    my @scripts;

    $wrk = "$WRK/correction"  if ($tag eq "cor");
    $wrk = "$WRK/trimming"    if ($tag eq "obt");
    $wrk = "$WRK/unitigging"  if ($tag eq "utg");

    make_path("$wrk.html.files")  if (! -e "$wrk.html.files");

    #  For correction runs
    if ($tag eq "cor") {
        push @body, "<h1>Correction</h1>\n";
        buildGatekeeperHTML($wrk, $asm, $tag, \@css, \@body, \@scripts);
        buildMerylHTML($wrk, $asm, $tag, \@css, \@body, \@scripts);
        buildOverlapperHTML($wrk, $asm, $tag, \@css, \@body, \@scripts);
        buildCorrectionHTML($wrk, $asm, $tag, \@css, \@body, \@scripts);
    }

    #  For trimming runs
    if ($tag eq "obt") {
        push @body, "<h1>Trimming</h1>\n";
        buildGatekeeperHTML($wrk, $asm, $tag, \@css, \@body, \@scripts);
        buildMerylHTML($wrk, $asm, $tag, \@css, \@body, \@scripts);
        buildOverlapperHTML($wrk, $asm, $tag, \@css, \@body, \@scripts);
        buildTrimmingHTML($wrk, $asm, $tag, \@css, \@body, \@scripts);
    }

    #  For assembly runs
    if ($tag eq "utg") {
        push @body, "<h1>Assembly</h1>\n";
        buildGatekeeperHTML($wrk, $asm, $tag, \@css, \@body, \@scripts);
        buildMerylHTML($wrk, $asm, $tag, \@css, \@body, \@scripts);
        buildOverlapperHTML($wrk, $asm, $tag, \@css, \@body, \@scripts);
        buildOverlapErrorCorrectionHTML($wrk, $asm, $tag, \@css, \@body, \@scripts);
        buildUnitiggerHTML($wrk, $asm, $tag, \@css, \@body, \@scripts);
        buildConsensusHTML($wrk, $asm, $tag, \@css, \@body, \@scripts);
        buildOutputHTML($wrk, $asm, $tag, \@css, \@body, \@scripts);
    }


    #print STDERR "WRITING '$wrk/$asm-summary.html'\n";

    open(F, "> $wrk.html") or die "can't open '$wrk.html' for writing: $!\n";

    print F "<!DOCTYPE html>\n";
    print F "\n";
    print F "<html>\n";
    print F "\n";
    print F "<head>\n";
    print F "<title>canu analysis for assembly '$asm' in directory '$wrk'</title>\n";
    print F "<style type='text/css'>\n";
    print F "body       { font-family: Helvetica, Verdana, sans-serif; }\n";
    print F "h1, h2, h3 { color: #ee3e80; }\n";
    print F "p          { color: #665544; }\n";
    print F "th, td     { border: 1px solid #111111; padding: 2px 2px 2px 2px; }\n";
    print F "td:hover   { background-color: #e4e4e4; }\n";
    print F "th:hover   { background-color: #d4d4d4; }\n";
    print F "tr.details { visibility: collapse; }\n";
    print F @css;
    print F "</style>\n";
    print F "</head>\n";
    print F "\n";
    print F "<body>\n";
    print F "\n";
    print F @body;
    print F "\n";
    print F "<script type='text/javascript'>\n";
    print F "var toggleTable = function() {\n";
    print F "  var table = this.closest('table');\n";
    print F "  var elts  = table.querySelectorAll('.details');\n";
    print F "\n";
    print F "  for (var i=0; i<elts.length; i++) {\n";
    print F "    if (!elts[i].enabled) {\n";
    print F "      elts[i].enabled = true;\n";
    print F "      elts[i].style.visibility = 'visible';\n";
    print F "    } else {\n";
    print F "      elts[i].enabled = false;\n";
    print F "      elts[i].style.visibility = 'collapse';\n";
    print F "    }\n";
    print F "  }\n";
    print F "}\n";
    print F @scripts;
    print F "</script>\n";
    print F "\n";
    print F "</body>\n";
    print F "\n";
    print F "</html>\n";

    close(F);
}

