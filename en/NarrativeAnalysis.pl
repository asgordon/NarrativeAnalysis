#!/usr/bin/perl

##############################################
#
# NarrativeAnalysis.pl
# 
# usage: perl NarrativeAnalysis.pl story.txt
#        where story.txt is a plain text file
#        containing a personal story.
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

$| = 1;

my $scdir = dirname( __FILE__ );
my $posmodname = "$scdir/swb.tagmod";
my $nemodname = "$scdir/narrativeLevel.mod";
my $osmodname = "$scdir/subjectivity.mod";
my $segmodname = "$scdir/segmentation.mod";

my %wpos = ();
my %wne = ();
my %wos = ();
my %wseg = ();

my @clpos = ();
my @clne = ();
my @clos = ();
my @clseg = ();

my @parr = ();

sub loadModel {
    my $modname = shift;
    my $w = shift;
    my $c = shift;
    
    open FP, "$modname" or die "Cannot open model $modname\n";

    my $clstr = <FP>;
    @{$c} = split ' ', $clstr;
    shift @{$c};

    while(<FP>) {
	my @arr = split;
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

sub postag {
    my $sent = shift;
    @parr = split ' ', $sent;
    my $prevtag = "*NONE*";
    my @posout = ();

    for( my $i = 0; $i < @parr; $i++ ) {
	my ( $word, $tag );
	my ( $wordp1, $tagp1 );
	my ( $wordp2, $tagp2 );
	my ( $wordn1, $tagn1 );
	my ( $wordn2, $tagn2 );

	( $word, $tag ) = &wordnotag( $i );
	( $wordp1, $tagp1 ) = &wordnotag( $i-1 );
	( $wordp2, $tagp2 ) = &wordnotag( $i-2 );
	( $wordn1, $tagn1 ) = &wordnotag( $i+1 );
	( $wordn2, $tagn2 ) = &wordnotag( $i+2 );

	my $lcword = &lc( $word );
	my $wf = &wfeat( $word );
	my $lcwordp1 = &lc( $wordp1 );
	my $wfp1 = &wfeat( $wordp1 );
	my $lcwordp2 = &lc( $wordp2 );
	my $wfp2 = &wfeat( $wordp2 );
	my $lcwordn1 = &lc( $wordn1 );
	my $wfn1 = &wfeat( $wordn1 );
	my $lcwordn2 = &lc( $wordn2 );
	my $wfn2 = &wfeat( $wordn2 );

	my ( $pref, $spref, $suf, $ssuf ) = &affix( $word );
	my ( $pref, $spref, $suf, $ssuf ) = &affix( $word );
	my ( $prefp1, $sprefp1, $sufp1, $ssufp1 ) = &affix( $wordp1 );
	my ( $prefn1, $sprefn1, $sufn1, $ssufn1 ) = &affix( $wordn1 );
	my ( $prefp2, $sprefp2, $sufp2, $ssufp2 ) = &affix( $wordp2 );
	my ( $prefn2, $sprefn2, $sufn2, $ssufn2 ) = &affix( $wordn2 );
	
	my $featstr = "";

	# curr
	$featstr .= "$word $lcword $wf $pref $spref $suf $ssuf ";

	# prev1
	$featstr .= "$lcwordp1 $wfp1 $prefp1 $sprefp1 $sufp1 $ssufp1 ";
	$featstr .= "$prevtag ";

	# next1
	$featstr .= "$lcwordn1 $wfn1 $prefn1 $sprefn1 $sufn1 $ssufn1 ";

	# prev2
	$featstr .= "$lcwordp2 $wfp2 $prefp2 $sufp2 ";
	
	# next2
	$featstr .= "$lcwordn2 $wfn2 $prefn2 $sufn2 ";

	# curr-prev1
	$featstr .= "$word~$wordp1 $lcword~$wfp1 $lcword~$lcwordp1 ";
	$featstr .= "$lcword~$prevtag $wf~$prevtag ";

	# curr-next1
	$featstr .= "$word~$wordn1 $lcword~$lcwordn1 $wfn1~$wf ";

	# prev1-next1
	$featstr .= "$lcwordp1~$lcwordn1 $wfp1~$wfn1";

	# prev1-curr-next1
	$featstr .= "$lcwordp1~$lcword~$lcwordn1 $wfp1~$wf~$wfn1";

	# prev2-prev1

	# prev2-prev1-curr

	# next2-next1

	# next2-next1-curr
	
	$featstr .= "\n";

	my @farr = split " ", $featstr;
	
	for( my $fi = 0; $fi < @farr; $fi++ ) {
	    $farr[$fi] = "$fi:$farr[$fi]";
	}

	$featstr = join " ", @farr;
	    
	$tag = &classify( \@farr, \%wpos, \@clpos );
	my $t1 = $tag;
	if( $t1 eq "BES" ) {
	    $t1 = "VBZ";
	}
	push @posout, { word => $word, tag => $t1 };

	$prevtag = $tag;
    }
    
    return @posout;
}

sub tokenize {
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

    $str =~ s/([^\.A-Z0-9])([\.])([A-Z0-9\n ])/$1 $2 $3/g;
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

    $str =~ s/\' / \' /g;
    $str =~ s/\"/ '' /g;
    $str =~ s/\'s / \'s /g;
    $str =~ s/\'S / \'S /g;
    $str =~ s/\'m / \'m /g;
    $str =~ s/\'M / \'M /g;
    $str =~ s/\'d / \'d /g;
    $str =~ s/\'D / \'D /g;
    $str =~ s/\'ll / \'ll /g;
    $str =~ s/\'re / \'re /g;
    $str =~ s/\'ve / \'ve /g;
    $str =~ s/n\'t / n\'t /g;
    $str =~ s/\'LL / \'LL /g;
    $str =~ s/\'RE / \'RE /g;
    $str =~ s/\'VE / \'VE /g;
    $str =~ s/N\'T / N\'T /g;
    
    $str =~ s/ Cannot / Can not /g;
    $str =~ s/ cannot / can not /g;
    $str =~ s/ D'ye / D' ye /g;
    $str =~ s/ d'ye / d' ye /g;
    $str =~ s/ Gimme / Gim me /g;
    $str =~ s/ gimme / gim me /g;
    $str =~ s/ Gonna / Gon na /g;
    $str =~ s/ gonna / gon na /g;
    $str =~ s/ Gotta / Got ta /g;
    $str =~ s/ gotta / got ta /g;
    $str =~ s/ Lemme / Lem me /g;
    $str =~ s/ lemme / lem me /g;
    $str =~ s/ More'n / More 'n /g;
    $str =~ s/ more'n / more 'n /g;
    $str =~ s/'Tis / 'T is /g;
    $str =~ s/'tis / 't is /g;
    $str =~ s/'Twas / 'T was /g;
    $str =~ s/'twas / 't was /g;
    $str =~ s/ Wanna / Wan na /g;
    $str =~ s/ wanna / wan na /g;

    return $str;
}

sub segment {
    my @post = @_;
    my @nsegs = ();
    my @currseg = ();

    my $maxn = @post;

    if( $maxn < 2 ) {
	my @segs = ();
	push @segs, [@post];
	return @segs;
    }

    for( my $i = 0; $i < $maxn; $i++ ) {
	my @f = ();
	
	push @currseg, $post[$i];
	
	push @f, "w:$post[$i]->{word} t:$post[$i]->{tag}";
	push @f, "wt:$post[$i]->{word}:$post[$i]->{tag}";
	push @f, "w-1:$post[$i-1]->{word} t-1:$post[$i-1]->{tag}";
	push @f, "w-2:$post[$i-2]->{word} t-2:$post[$i-2]->{tag}";
	push @f, "w+1:$post[$i+1]->{word} t+1:$post[$i+1]->{tag}";
	push @f, "w+2:$post[$i+2]->{word} t+2:$post[$i+2]->{tag}";
	
	push @f, "ww-1:$post[$i]->{word}:$post[$i-1]->{word}";
	push @f, "ww+1:$post[$i]->{word}:$post[$i+1]->{word}";
	push @f, "ww-1w+1:$post[$i]->{word}:$post[$i+1]->{word}:$post[$i-1]->{word}";
	push @f, "tt-1:$post[$i]->{tag}:$post[$i-1]->{tag}";
	push @f, "tt+1:$post[$i]->{tag}:$post[$i+1]->{tag}";
	push @f, "tt-1t+1:$post[$i]->{tag}:$post[$i-1]->{tag}:$post[$i+1]->{tag}";
	push @f, "t-1w:$post[$i-1]->{tag}:$post[$i]->{word}";
	push @f, "t+1w:$post[$i+1]->{tag}:$post[$i]->{word}";
	push @f, "t-1wt+1:$post[$i-1]->{tag}:$post[$i]->{word}:$post[$i+1]->{tag}";
	push @f, "t-1tt+1:$post[$i-1]->{tag}:$post[$i]->{tag}:$post[$i+1]->{tag}";
	push @f, "t-2t-1tt+1:$post[$i-2]->{tag}:$post[$i-1]->{tag}:$post[$i]->{tag}:$post[$i+1]->{tag}";
	push @f, "t+2t-1tt+1:$post[$i+2]->{tag}:$post[$i-1]->{tag}:$post[$i]->{tag}:$post[$i+1]->{tag}";
	push @f, "t-2t-1tt+1t+2:$post[$i-2]->{tag}:$post[$i-1]->{tag}:$post[$i]->{tag}:$post[$i+1]->{tag}:$post[$i+2]->{tag}";
	push @f, "t-2t-1wt+1t+2:$post[$i-2]->{tag}:$post[$i-1]->{tag}:$post[$i]->{word}:$post[$i+1]->{tag}:$post[$i+2]->{tag}";
	push @f, "t-2w-1wt+1t+2:$post[$i-2]->{tag}:$post[$i-1]->{word}:$post[$i]->{word}:$post[$i+1]->{tag}:$post[$i+2]->{tag}";
	push @f, "ww+1w+2w+3:$post[$i]->{word}:$post[$i+1]->{word}:$post[$i+2]->{word}:$post[$i+3]->{word}";
	push @f, "w+2w+3:$post[$i+2]->{word}:$post[$i+3]->{word}";
	push @f, "t-2t-1ww+1t+2:$post[$i-2]->{tag}:$post[$i-1]->{tag}:$post[$i]->{word}:$post[$i+1]->{word}:$post[$i+2]->{tag}";	    

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
	push @f, "w:$post[$i]->{word} t:$post[$i]->{tag}";
	push @f, "ww:$post[$i]->{word}:$post[$i-1]->{word}";
	push @f, "tt:$post[$i]->{tag}:$post[$i-1]->{tag}";
	push @f, "tw:$post[$i-1]->{tag}:$post[$i]->{word}";
	push @f, "ttt:$post[$i-2]->{tag}:$post[$i-1]->{tag}:$post[$i]->{tag}";
    }

    my $ne = &classify( \@f, \%wne, \@clne );
    my $os = &classify( \@f, \%wos, \@clos );

    return ($ne, $os);
}

print STDERR "Loading models.\n";

&loadModel( $posmodname, \%wpos, \@clpos );
&loadModel( $segmodname, \%wseg, \@clseg );
&loadModel( $nemodname, \%wne, \@clne );
&loadModel( $osmodname, \%wos, \@clos );

print STDERR "Finished loading models.\n";

while( <> ) {
    s/[\n\r]+//g;
    my @post = &wtag( &tokenize( $_ ) );
    my @nsegs = &segment( @post );
    
    foreach my $s ( @nsegs ) {
	
	my $segstr = "";
	foreach my $str ( @{$s} ) {
	    $segstr .= "$str->{word} ";
	}

	my @pseg = &postag( $segstr );

	my ($ne, $os) = &narrativeLevel( \@pseg );
	print "$ne\t$os\t$segstr\n";
    }
}

 
