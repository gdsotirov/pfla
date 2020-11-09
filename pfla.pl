#!/usr/bin/perl

use Getopt::Long;
$DEBUG = 1;
$TEST  = 1;

# ************************************************************************
# *          ProFTPD Log Analyzer v0.03 by Georgi D. Sotirov             *
# ************************************************************************
# *   This PERL programm can analyze the proFTPD xferlog and to present  *
# * the information in plain text or html format.                        *
# ************************************************************************
# * Date : Nov 09 2020 (2020-11-09)                                      *
# ************************************************************************
# * 2001-2020 (c) Georgi Dimitrov Sotirov, <gdsotirov@gmail.com>         *
# ************************************************************************

# Identification values
$GENERATOR    = "ProFTPD Log Analyzer (PFLA) v0.03";
$GEN_HOMEPAGE = "https://github.com/gdsotirov/pfla";
$AUTHOR       = "Georgi D. Sotirov";
$AEMAIL       = "gdsotirov\@gmail.com";

$Version = '';

GetOptions("version", \$Version);

if ( $Version == 1 ) {
    &version;
    exit 0;
} 

# Used files
# Note: Edit here if the files are in other places
$systemlog  = "/var/log/proftpd/proftpd.log";
$xferlog    = "/var/log/proftpd/xferlog";
$templfile  = "report.templ.html";
$outputfile = "/var/www/htdocs/pfla/report.html";

# Check the needed access to files
if ( ! -r $systemlog ) {
    die "$0: Error: Cannot read from proftpd log file $systemlog!\n";
}

if ( ! -z $xferlog ) {
    push(@xferlogs, $xferlog);
}

# Additional logs are collected in the xferlogs list, but only if not zero
# in size - I mean '! -z' ;-)
$logsufix = 1;
for ( ;; ) {
    $xferlogname = $xferlog.".".$logsufix;
    if ( -e $xferlogname ) {
        if ( ! -z $xferlogname ) {
            push(@xferlogs, $xferlogname);
        }
        $logsufix++;
    }
    else {
        last;        # exit from cycle - there is no more logs
    }
}

if ( ! -r $templfile ) {
    die "$0: Error: Cannot read from source file $templfile!\n";
}

# Subroutines prototypes
sub version;
sub hrbytes;
sub summaryrep;

# Initialization
$hostname        = "unknown host";
$transf_first    = "unknown";
$transf_last     = "unknown";
$total_transfer  = 0;
$total_outgoing  = 0;
$total_incoming  = 0;
$total_files     = 0;
$total_out_files = 0;
$total_in_files  = 0;
$total_del_files = 0;
$total_ascii     = 0;
$total_binary    = 0;
$total_compl     = 0;
$total_incom     = 0;
$total_usrs      = 0;
$total_anon      = 0;
$total_guest     = 0;
$total_real      = 0;
$total_time      = 0;

$hostname = `hostname`;
chomp($hostname);

{
    my $firstlog = $xferlogs[@xferlogs-1];
    $transf_first = `head -1 $firstlog`;
    while ( length($transf_first) > 24 ) {
        chop($transf_first);
    }
}

$transf_last = `tail -1 $xferlogs[0]`;
while ( length($transf_last) > 24 ) {
    chop($transf_last);
}

foreach $XLOG (@xferlogs) {
    open(XFERLOG, $XLOG);

    while ( <XFERLOG> ) {
        @VALS = split(/ +/, $_);
        chomp(@VALS);

        $total_time += $VALS[5];
        if ( $VALS[17] eq "c" ) {
            if ( $VALS[11] ne "d" ) {
                $total_transfer += $VALS[7];
                $total_files++;
                $total_compl++;

                if ( $VALS[11] eq "o" ) {
                    $total_outgoing += $VALS[7];
                    $total_out_files++;
                }
                else {
                    $total_incoming += $VALS[7];
                    $total_in_files++;
                }
            }
            else {
                $total_del_files++;
            }
        }
        else {
            $total_incom++;
        }

        if ( $VALS[9] eq "a" ) {
            $total_ascii++;
        }
        elsif ( $VALS[9] eq "b" ) {
            $total_binary++;
        }

        # Transfers count for Anonymous/Guest/Real users
        if ( $VALS[12] eq "a" ) {
            $total_anon++;
        }
        elsif ( $VALS[12] eq "g" ) {
            $total_guest++;
        }
        elsif ( $VALS[12] eq "r" ) {
            $total_real++;
        }
    } # while

    close(XFERLOG);
} # foreach

$temp = &hrbytes($total_transfer);
$total_transfer = sprintf("%s (%d B)", $temp, $total_transfer);
$temp = &hrbytes($total_outgoing);
$total_outgoing = sprintf("%s (%d B)", $temp, $total_outgoing);
$temp = &hrbytes($total_incoming);
$total_incoming = sprintf("%s (%d B)", $temp, $total_incoming);
$total_time = &hrtime($total_time);

if ( !open(OUTPUTFILE, ">$outputfile") ) {
    die "Cannot open or create the output file $outputfile!\n";
}

$gen_date = localtime;

if ( open(TEMPLFILE, $templfile) ) {
    while ( <TEMPLFILE> ) {
        s/\$generator/$GENERATOR/gi;
        s/\$hostname/$hostname/gi;
        s/\$gen_date/$gen_date/gi;
        s/\$transf_first/$transf_first/gi;
        s/\$transf_last/$transf_last/gi;
        s/\$total_transfer/$total_transfer/gi;
        s/\$total_outgoing/$total_outgoing/gi;
        s/\$total_incoming/$total_incoming/gi;
        s/\$total_files/$total_files/gi;
        s/\$total_out_files/$total_out_files/gi;
        s/\$total_in_files/$total_in_files/gi;
        s/\$total_del_files/$total_del_files/gi;
        s/\$total_ascii/$total_ascii/gi;
        s/\$total_binary/$total_binary/gi;
        s/\$total_compl/$total_compl/gi;
        s/\$total_incom/$total_incom/gi;
        s/\$total_usrs/$total_usrs/gi;
        s/\$total_anon/$total_anon/gi;
        s/\$total_guest/$total_guest/gi;
        s/\$total_real/$total_real/gi;
        s/\$total_time/$total_time/gi;
        s/\$GENERATOR/$GENERATOR/gi;
        s/\$GEN_HOMEPAGE/$GEN_HOMEPAGE/gi;
        s/\$AUTHOR/$AUTHOR/gi;
        s/\$AEMAIL/$AEMAIL/gi;

        print OUTPUTFILE $_;
    }
}

close(OUTPUTFILE);
close(TEMPLFILE);

# ************************************************************************
# * Subroutine: usage                                                    *
# * Purpose   : Prints the programm usage information.                   *
# * Modified  : Jan 14 2002                                              *
# ************************************************************************

sub version {
    print "\n$GENERATOR\n";
    print "Author: $AUTHOR <$AEMAIL>\n";
    print "Please, visit $GEN_HOMEPAGE\n";
    print "\n"; 
}

# ************************************************************************
# * Subroutine: hrbytes                                                  *
# * Purpose   : Represents a value in bytes to a human readable string,  *
# *             e.g. 12345 B = 12.05 KB.                                 *
# * Modified  : Jan 4 2002                                               *
# ************************************************************************

sub hrbytes {
    $bytes = $_[0];
    @BYTES = ("B", "KB", "MB", "GB", "TB");
    $B = 0;
    while ( $bytes > 1024 ) {
        $bytes /= 1024;
        $B++;
    }

    return sprintf("%7.3f %s", $bytes, $BYTES[$B]);
}

# ************************************************************************
# * Subroutine: hrtime                                                   *
# * Purpose   : Represents a value in seconds to a human readable time,  *
# *             e.g. 3669 seconds = 1h 1m 9s.                            *
# * Modified  : Jan 6 2002                                               *
# ************************************************************************

sub hrtime {
    $secs = $seconds = $_[0];
    $hrs = 0;
    while ( $secs > 3600 ) {
        $hrs++;
        $secs -= 3600;
    }
    $mins = 0;
    while ( $secs > 60 ) {
        $mins++;
        $secs -= 60;
    }

    if ( $mins != 0 ) {
        if ( $hrs != 0 ) {
            return sprintf("%dh %dm %ds (%d s)", $hrs, $mins, $secs, $seconds);
        }
        else {
            return sprintf("%dm %ds (%d s)", $mins, $secs, $seconds);
        }
    }
    else {
        return sprintf("%d seconds", $seconds);
    }
}

