#!/usr/bin/perl

# ************************************************************************
# *          ProFTPD Log Analyzer v0.01 by Georgi D. Sotirov             *
# ************************************************************************
# *   This PERL programm can analyze the proFTPD xferlog and to present  *
# * the information in plain text or html format.                        *
# ************************************************************************
# * Date : Dec 12 2001 (12-12-2001)                                      *
# ************************************************************************
# * 2001 (c) Georgi Dimitrov Sotirov, <sotirov@bitex.com>                *
# ************************************************************************

# Identification values
$GENERATOR    = "ProFTPD Log Analyzer v0.01";
$GEN_HOMEPAGE = "ahost.com/pfla";
$AUTHOR       = "Georgi D. Sotirov";
$AEMAIL       = "sotirov\@bitex.com";

# Used files
$systemlog  = "/var/log/proftpd.log";
$xferlog    = "/var/log/xferlog";
$templfile  = "./report.templ.html";
$outputfile = "./report.html";

# Check the needed access to files
if ( ! -r $systemlog ) {
    die "Cannot read from proftpd log file $systemlog!\n";
}
if ( ! -r $xferlog ) {
    die "Cannot read from xferlog file $xferlog!\n";
}

if ( ! -r $templfile ) {
    die "Cannot read from source file $templfile!\n";
}

# Subroutines prototypes
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

$transf_first = `head -1 $xferlog`;
while ( length($transf_first) > 24 ) {
    chop($transf_first);
}

$transf_last = `tail -1 $xferlog`;
while ( length($transf_last) > 24 ) {
    chop($transf_last);
}


open(XFERLOG, $xferlog);

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
}

close(XFERLOG);

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
# * Subroutine: hrbytes                                                  *
# * Purpose   : Represents a value in bytes to a human readable string,  *
# *             e.g. 12345 B = 12.05 KB.                                 *
# * Modifyed  : Jan 4 2002                                               *
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
# * Modifyed  : Jan 6 2002                                               *
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

