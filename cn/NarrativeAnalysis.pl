#!/usr/bin/perl

##############################################
#
# NarrativeAnalysis.pl
# 
# usage: perl NarrativeAnalysis.pl story.txt
#        where story.txt is a plain text file
#        containing a personal story.
#
# Language: CHINESE
#
##############################################

=license

Copyright (c) 2014, University of Southern California
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met: 

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer. 
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution. 

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

use strict;
use File::Basename;
use Encode;

binmode STDOUT, ":utf8";

$| = 1;

my $scdir = dirname( __FILE__ );
my $nemodname = "$scdir/narrativeLevel.mod";
my $osmodname = "$scdir/subjectivity.mod";
my $segmodname = "$scdir/segmentation.mod";
my $clusterfname = "$scdir/paths";
my $tokmodname = "$scdir/wsegcombo.mod";

my %c = ();
my %wne = ();
my %wos = ();
my %wseg = ();
my %wtok = ();

my @clne = ();
my @clos = ();
my @clseg = ();
my @cltok = ();

my @parr = ();

#open FP, $clusterfname or die "Cannot open cluster file $clusterfname\n";
#while( <FP> ) {
#    my @a = split;
#    $a[0] =~ s/^(...).*/$1/;
#    $c{$a[1]} = $a[0];
#}
#close FP;

sub getcode {
    my $str = shift;
    my $code = "*";
    my @cp = unpack 'U*', $str;
    my $ww = join ':', @cp;
    if( exists $c{"[$ww]"} ) {
	$code = $c{"[$ww]"};
    }
    return $code;
}

sub loadModel {
    my $modname = shift;
    my $w = shift;
    my $c = shift;
    
    open FP, "$modname" or die "Cannot open model $modname\n";

    my $clstr = <FP>;
    @{$c} = split ' ', $clstr;
    shift @{$c};

    while(<FP>) {
	my $estr = decode('utf8', $_);
	my @arr = split ' ', $estr;

	my $fname = shift @arr;
	my $i = 0;
	foreach my $fw (@arr) {
	    if( $fw != 0 ) {
		${$w->{$fname}}{$i} = $fw;
	    }
	    $i++;
	}
    }
    
    close FP;
}

sub classify {
    my $feats = shift;
    my $w = shift;
    my $c = shift;
    
    my @res = ();
    my @ff = @{$feats};
    unshift @ff, "**BIAS**";

    foreach my $f (@ff) {
        if (exists $w->{$f}) {
            for (my $i = 0; $i < @{$c}; $i++) {
		if( exists $w->{$f}{$i} ) {
		    $res[$i] += $w->{$f}{$i};
		}
            }
        }
    }

    my @fres = ();
    for (my $i = 0; $i < @res; $i++) {
        $fres[$i] = {
            cname => $c->[$i],
            weight => $res[$i],
        };
    }

    @fres = sort {$b->{weight} <=> $a->{weight}} @fres;
    my $bestlabel = $fres[0]->{cname};
    if ($bestlabel eq "") {
        $bestlabel = "NONE";
    }
    
    return $bestlabel;
}

sub wordtag {
    my $idx = shift;

    if( $idx < 0 ) {
	return ( "lw", "LW" );
    }

    if( $idx >= @parr ) {
	return ( "rw", "RW" );
    }

    my $str = $parr[$idx];
    $str =~ /^(.+)\/([^\/]+)$/;
    return ($1, $2);
}

sub wordnotag {
    my $idx = shift;

    if( $idx < 0 ) {
	return ( "lw", "LW" );
    }

    if( $idx >= @parr ) {
	return ( "rw", "RW" );
    }

    my $str = $parr[$idx];
    return ($str, "NONE");
}

sub lc {
    my $str = shift;
    $str =~ tr/[A-Z]/[a-z]/;
    return $str;
}

sub affix {
    my $str = shift;

    $str =~ /(...)$/;
    my $s1 = $1;
    $str =~ /(..)$/;
    my $s2 = $1;

    $str =~ /^(...)/;
    my $p1 = $1;
    $str =~ /^(..)/;
    my $p2 = $1;

    if( $s1 eq "" ) { $s1 = $str; }
    if( $s2 eq "" ) { $s2 = $str; }
    if( $p1 eq "" ) { $p1 = $str; }
    if( $p2 eq "" ) { $p2 = $str; }

    return ( $p1, $p2, $s1, $s2 );
}

sub wfeat {
    my $str = shift;

    $str =~ s/[a-z]+/a/g;
    $str =~ s/[A-Z]+/A/g;
    $str =~ s/[0-9]+/1/g;
    $str =~ s/[^a-zA-Z0-9]+/./g;

    return $str;
}

sub wtag {
    my $sent = shift;
    @parr = split ' ', $sent;
    my @posout = ();

    for( my $i = 0; $i < @parr; $i++ ) {
	my ( $word, $tag ) = &wordnotag( $i );
	push @posout, { word => $word, tag => &wfeat($word) };
    }

    return @posout;
}

sub tag {
    my $str = shift;
    my @ws = split ' ', $str;
    my @post = ();
    foreach my $w ( @ws ) {
	my $code = &getcode( $w );
	my @c = unpack 'U*', $w;
	$code = "$code:$c[-1]:$c[-2]";
	push @post, { word => $w, tag => $code };
    }

    return @post;
}

sub tokenize1 {
    my $str = shift;
    
    $str =~ s/^\"/`` /;
    $str =~ s/ \"/ `` /g;
    $str =~ s/\(\"/( `` /g;
    $str =~ s/\[\"/[ `` /g;
    $str =~ s/\{\"/{ `` /g;
    $str =~ s/\<\"/< `` /g;
 
    $str =~ s/\.\.\./ \.\.\. /g;

    $str =~ s/\,/ , /g;
    $str =~ s/\;/ ; /g;
    $str =~ s/\:/ : /g;
    $str =~ s/\@/ @ /g;
    $str =~ s/\#/ \# /g;
    $str =~ s/\$/ \$ /g;
    $str =~ s/\%/ \% /g;
    $str =~ s/\&/ \& /g;
    $str =~ s/\!/ \! /g;
    $str =~ s/\?/ \? /g;

    $str =~ s/([^\.])([\.])[A-Z0-9\n ]/$1 $2 /g;
    $str =~ s/([^\.])([\.])[\n \t]*$/$1 $2/;

    $str =~ s/\[/ \[ /g;
    $str =~ s/\]/ \] /g;
    $str =~ s/\(/ \( /g;
    $str =~ s/\)/ \) /g;
    $str =~ s/\{/ \{ /g;
    $str =~ s/\}/ \} /g;
    $str =~ s/\</ \< /g;
    $str =~ s/\>/ \> /g;
    $str =~ s/\-\-/ \-\- /g;
    $str =~ s/([«»])/ $1 /g;

    $str =~ s/\"/ '' /g;

    $str =~ s/\' / \' /g;
    

    return $str;
}

sub tokenize {
    s/[\n\r]*//g;
    s/  +/ /g;

    my $estr = decode('utf8', $_);
    my @a1 = split /(?<=.)/, $estr;

    push @a1, " ";

    my @w = ();

    my $pw = "BOS";
    my $pw2 = "BOS";
    my $currw = "";
    unshift @a1, "BOS";
    push @a1, "EOS";
 
    for( my $i = 1; $i < @a1 - 1; $i++ ) {
	my @f = ();
	$currw .= $a1[$i];

        push @f, "currchar:$a1[$i]";
        push @f, "nextchar:$a1[$i+1]"; 
	push @f, "ccnc:$a1[$i]:$a1[$i+1]";
        push @f, "prevchar:$a1[$i-1]"; 
	push @f, "ccpc:$a1[$i]:$a1[$i-1]";
        push @f, "w:$currw";
        push @f, "prevw:$pw";
	push @f, "prevw2:$pw2";
	push @f, "w:pw:$currw:$pw";
	push @f, "w:pw:pw2:$currw:$pw:$pw2";

	my $lab = &classify( \@f, \%wtok, \@cltok );
	
	if( $lab eq "BRK" ) {
	    push @w, $currw;
	    $pw2 = $pw;
	    $pw = $currw;
	    $currw = "";
	}
    }

    my $str = join " ", @w;
    return $str;

}

sub segment {
    my @post = @_;
    my @nsegs = ();
    my @currseg = ();

    my $maxn = @post;

    for( my $i = 0; $i < $maxn; $i++ ) {
	my @f = ();
	
	push @currseg, $post[$i];

	if( $post[$i]->{word} =~ /^\.+$/ ) {
	    push @nsegs, [@currseg];
	    @currseg = ();
	    next;
	}

	push @f, "w:$post[$i]->{word}";
	push @f, "w1:$post[$i-1]->{word}";
	push @f, "w-1:$post[$i+1]->{word}";
	push @f, "w2:$post[$i-2]->{word}";
	push @f, "w-2:$post[$i+2]->{word}";
	push @f, "ww1:$post[$i]->{word}:$post[$i+1]->{word}";
	push @f, "ww-1:$post[$i]->{word}:$post[$i-1]->{word}";
	push @f, "ww1w-1:$post[$i]->{word}:$post[$i+1]->{word}:$post[$i-1]->{word}";
	push @f, "ww-1w-2:$post[$i]->{word}:$post[$i-1]->{word}:$post[$i-2]->{word}";
	push @f, "ww-1w-2w-3:$post[$i]->{word}:$post[$i-1]->{word}:$post[$i-2]->{word}:$post[$i-3]->{word}";
	push @f, "ww+1w+2:$post[$i]->{word}:$post[$i+1]->{word}:$post[$i+2]->{word}";
	push @f, "ww+1w+2w+3:$post[$i]->{word}:$post[$i+1]->{word}:$post[$i+2]->{word}:$post[$i+3]->{word}";
	push @f, "ww+1w+2w-1:$post[$i]->{word}:$post[$i+1]->{word}:$post[$i+2]->{word}:$post[$i-1]->{word}";
	push @f, "ww-11w2w1:$post[$i]->{word}:$post[$i-1]->{word}:$post[$i+2]->{word}:$post[$i+1]->{word}";

	my $segm = &classify( \@f, \%wseg, \@clseg );
	
	if( $segm eq "BRK" ) {
	    push @nsegs, [@currseg];
	    @currseg = ();
	}
    }

    if( @currseg ) {
	push @nsegs, [@currseg];
    }

    return @nsegs;
}

sub narrativeLevel {
    my $pref = shift;
    my @post = @{$pref};

    push @post, { word => "RW", tag => "RW" };
    push @post, { word => "RW", tag => "RW" };
    push @post, { word => "RW", tag => "RW" };
    unshift @post, { word => "LW", tag => "LW" };
    unshift @post, { word => "LW", tag => "LW" };
    unshift @post, { word => "LW", tag => "LW" };

    my @f = ();
    for( my $i = 3; $i < @post - 3; $i++ ) {
	push @f, "w:$post[$i]->{word}";
	push @f, "ww:$post[$i-1]->{word}:$post[$i]->{word}";
    }

    my $ne = &classify( \@f, \%wne, \@clne );
    my $os = &classify( \@f, \%wos, \@clos );

    return ($ne, $os);
}

print STDERR "Loading models.\n";

&loadModel( $segmodname, \%wseg, \@clseg );
&loadModel( $nemodname, \%wne, \@clne );
&loadModel( $osmodname, \%wos, \@clos );
&loadModel( $tokmodname, \%wtok, \@cltok );

print STDERR "Finished loading models.\n";

while( <> ) {
    s/[\n\r]+//g;
    my $estr = decode('utf8', $_);

    my @post = &tag( &tokenize( $estr ) );
    my @nsegs = &segment( @post );
    
    foreach my $s ( @nsegs ) {
	
	my $segstr = "";
	foreach my $str ( @{$s} ) {
	    $segstr .= "$str->{word} ";
	}

	my ($ne, $os) = &narrativeLevel( $s );
	print "$ne\t$os\t$segstr\n";
    }
}

 
