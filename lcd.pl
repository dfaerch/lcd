#!/usr/bin/perl -w
#
# lcd - the Locate Change Dir command. Copyright 2016 - Dan Faerch.
# 
# License: GPL 3.0 or later
#

use warnings;
use strict;
use Cwd;

# TODO/IDEA: augment list of dirs with a scan of bash/zsh/* history.
my $LOCATE_BIN="locate";
my $DEBUG = 0;


my @search = @ARGV;
if (!@search ) {
    print  STDERR "Must supply a search string\n";
    print ".";
    exit 1;
}


# STUB
#-----
# Is this an lcd - \d+? Step back in history
if (join(" ",@search) =~ m/^- (\d+)/) {
    # We cant currently, but this space is reserved for that
    print STDERR "currently not implemented\n";
    
    # TODO: Keep an LCDHIST env-var, with n dirs seperated by : (like path). 
    # split here and pick the item chosen by user.
    
    exit;
}
#-----



# Make regex
@search = map { quotemeta } @search;

my $search = "(".join('.*?', @search);
$search .= ')[^\/]*$';
$search =~ s/'/\'/;

my $is_lowercase = (lc $search eq $search);
my $i = "";
$i = "(?i)" if $is_lowercase;
my $search_qr = qr/$i$search/;



# Run locate
my $cmd = $LOCATE_BIN;
$cmd .= " -i" if $is_lowercase;
$cmd .= " --regex '$search'";

print STDERR $cmd."\n" if $DEBUG;


# Filter once more, since locate doesnt do it right
my @files = grep {m/$search_qr/} `$cmd`;

# Sort using our own sort function
my @sdirs = multi_sort(@files);

my $index = 0;
my $cwd = getcwd();

# See if we are currently standing in a matched directory and assume we want to go the the next one
if (my @match = grep { $sdirs[$_] eq $cwd."\n" } 0..$#sdirs) {
    my $i = $match[0]+1;
    if ($i <= @sdirs) {
        $index = $i % @sdirs;
    }
}


my $result;
# Pick the first dir, after index. (because locate also prints files)
for (my $i = $index;$i<@sdirs;$i++) {
    my $e = $sdirs[$i];
    chomp($e);
    if ( -d $e && -x $e) {
        $result = $e;
        last;
    }
}

if (!defined $result || $result eq $cwd) {

    print STDERR "Nothing found\n";
    
} else {

    print STDERR $result."\n";
    $result =~ s/'/'\\''/g;
    print "cd '".$result."'\n";

}

#----------------

sub multi_sort {
    my @files = @_;
    
    my $home = $ENV{HOME};
    my $home_depth =()= $home =~ m%/%g;    
    
    my @temp;
    foreach (@files) {
        my %h = ();

        # Store original
        $h{org} = $_;
        # Length
        $h{len} = length($_);

        # DEPTH
        #----
        # Count slashes
        $h{depth} =()= $_ =~ m%/%g;
        # Subtract home depth, to prioritize things in users home
        if (m%^\Q$home\E/%) {
            $h{depth} -= $home_depth 
        } elsif ( m%^/home/% ) {
            #add 1 depth, if path is within another home dir
            $h{depth} += 1 if (m%/\.%);
        }


        #add 1 depth, if path is within a hidden dir (eg .config)
        $h{depth} += 1 if (m%/\.%);
        

        # Length after match
        # ------- 
        # Sliding window search looking for the match closest to the end and store how far from the end it is
        my $tmp = $_;
        my $mpos;
        my $epos = 0;
        while ($tmp =~ m/$search_qr/) {
            # store length - end-pos of last match
            $mpos = 0 if !defined $mpos;
            $mpos += $-[1];

            # Chop away anything before match, +1, and try again (sliding window match)
            $tmp = substr($tmp,$-[1]+1);
            $epos = length($1)+1; # add one for the chopped of letter
        }

        if (defined $mpos) {
            $h{len_after_match} = $h{len} - ($mpos+$epos+1);
        } else {
            $h{len_after_match} = $h{len};
            print STDERR "Error - NO MATCH? $search_qr - $_\n";
        }

        
        # Perfect last dir
        # ---------
        # If searchstring perfectly matches the last dir, sort higher (eg. search apache, sorts "apache" higher than "apache2")
        m%/([^/]+)$%;
        my $last_part = "/".$1;
        
        if ( $last_part =~ m%$search_qr% ) {
            $h{perfect_last_dir} = 1;
        } else {
            $h{perfect_last_dir} = 0;
        }

        push @temp,\%h;
        
    }
    

    #print Dumper(\@temp);
    
     return
             map  { $_->{org} } 
              sort { 
                 $a->{perfect_last_dir} <=> $b->{perfect_last_dir}
                 || $a->{depth} <=> $b->{depth}
                 || $a->{len_after_match} <=> $b->{len_after_match} 
                 || $a->{len} <=> $b->{len} 
                 } @temp;    
}
