#!/usr/bin/perl
#stats by Dale Swanson July 11 2013
#requires gnuplot


use strict;
use warnings;
use autodie;
use Cwd 'abs_path';
abs_path($0) =~ m/(.*\/)/;
my $dir = $1; #directory path of script


#$|++; #autoflush disk buffer

my $inputband = "";
if (!$inputband) {$inputband = $ARGV[0];}
my $station = "WMGK";
my $limit = 30;
my $inputfile = "allsongs.txt";
my $topsongs = "$station.$inputband.songs.csv";
my $hoursfile = "$station.$inputband.hours.csv";
my $gnuplotfile = "plot.gp";
my $debug = 0;
my $linxdump = $dir."lastfm.$inputband.txt";


my $days = 0;
my $lastday = 0;
my $earliest;
my $latest;
my @filearray; #stores lines of input files
my $fileline; #store individual lines of input file in for loops
my ($year, $mon, $day, $hour, $min);
my $band;
my $song;
my $fullsongname;
my %songs;
my %bands;
my @songplays;
my @allhours;
my @bandhours;


my $apikey = "2793cfec711769c9b1a09886fb12ad0b";
my $fmtitle;
my $fmband = $inputband;
my %fmsongs;


my %alias;
#$alias{"WMGK Version"} = "Last.fm Version";
$alias{"1984/Jump"} = "Jump";
$alias{"Ain't Talkin' Bout Love"} = "Ain't Talkin' 'Bout Love";
$alias{"Running With The Devil"} = "Runnin' With the Devil";
$alias{"Squeezebox"} = "Squeeze Box";
$alias{"Heartbreaker/Living Loving M"} = "Heartbreaker";
$alias{"Sgt. Pepper's (Reprise)A Day"} = "A Day in the Life";
$alias{"It's Only Rock 'n' Roll (But"} = "It's Only Rock 'n Roll (But I Like It)";
$alias{"Golden Slumbers/Carry That W"} = "Golden Slumbers";
$alias{"Ballad Of John And Yoko"} = "The Ballad of John and Yoko";
$alias{"Oh Darling"} = "Oh! Darling";
$alias{"Bron-Y Aur Stomp"} = "Bron-Y-Aur Stomp";
$alias{"Empty Spaces/Young Lust"} = "Young Lust";
$alias{"Brain Damage/ Eclipse"} = "Brain Damage";
$alias{"Long Distance Run Around/Fis"} = "Long Distance Runaround";
$alias{"Goin' Mobile"} = "Going Mobile";
$alias{"Eruption/You Really Got Me"} = "You Really Got Me";
$alias{"We Will Rock You/ We Are The"} = "We Will Rock You";
$alias{"Journey;Feeling That Way/Anytime"} = "Anytime";
$alias{"Bye-Bye Love"} = "Bye Bye Love";
$alias{"L. A. Woman"} = "L.A. Woman";
$alias{"Threshold/Jet Airliner"} = "Jet Airliner";
$alias{"Space Intro/Fly Like An Eagl"} = "Fly Like An Eagle";
$alias{"I've Got A Rock And Roll Hea"} = "I've Got A Rock 'N' Roll Heart";
$alias{"Rock And Roll Fantasy"} = "Rock 'n' Roll Fantasy";
$alias{"(Don't Fear) The Reaper"} = "(Don't Fear) The Reaper";
$alias{"Foreplay / Long Time"} = "Foreplay/Long Time";
$alias{"Lovin' Touchin' Squeezin'"} = "Lovin', Touchin', Squeezin'";
$alias{"Maybe I'm Amazed (Live)"} = "Maybe I'm Amazed";
$alias{"Rock And Roll Band"} = "Rock & Roll Band";



#wget "http://ws.audioscrobbler.com/2.0/?method=artist.getcorrection&artist=beatles&api_key=2793cfec711769c9b1a09886fb12ad0b" -O -  >dump.txt
my $temp = "wget \"http://ws.audioscrobbler.com/2.0/?method=artist.getcorrection&artist=$inputband&api_key=$apikey\" -O -  >\"$linxdump\"";
#print "\n$temp\n";
if (!$debug) {system($temp);} #download page when not debug
#if ($debug) {$linxdump = "dump.txt";} #if debug use saved page

open my $ifile, '<', $linxdump;
@filearray = <$ifile>;
close $ifile;
foreach $fileline (@filearray)
{#go through the linx dump, gather data
	#<name>The Beatles</name>
	if ($fileline =~ m/<name>(.+)<\/name>/)
	{#this line should contain song title
		$fmband = $1;
		$fmband =~ s/(['|\w]+)/\u\L$1/g; #Title Case
	}
}



#wget "http://ws.audioscrobbler.com/2.0/?method=artist.gettoptracks&artist=rush&api_key=2793cfec711769c9b1a09886fb12ad0b" -O -  >dump.txt
$temp = "wget \"http://ws.audioscrobbler.com/2.0/?method=artist.gettoptracks&limit=200&artist=$fmband&api_key=$apikey\" -O -  >\"$linxdump\"";
#print "\n$temp\n";
if (!$debug) {system($temp);} #download page when not debug
if ($debug) {$linxdump = "dump.txt";} #if debug use saved page

open $ifile, '<', $linxdump;
@filearray = <$ifile>;
close $ifile;
foreach $fileline (@filearray)
{#go through the linx dump, gather data
	#    <name>Tom Sawyer</name>
	if ($fileline =~ m/^\s{4}<name>(.+)<\/name>/)
	{#this line should contain song title
		#$fmtitle = $1;
		$fmtitle = substr( $1, 0, 20 );
		$fmtitle =~ s/\&amp\;/\&/g; #ampersands
		$fmtitle =~ s/(['|\w]+)/\u\L$1/g; #Title Case
		print "\nName: $fmtitle ";
	}
	elsif ($fileline =~ m/^\s{12}<playcount>(\d+)<\/playcount>/)
	{#the playcount
		$fmsongs{$fmtitle} //= $1; #only if we haven't already found it
		#print "\nCount: $1";
	}
}

open $ifile, '<', $inputfile;
@filearray = <$ifile>;
close $ifile;
foreach $fileline (@filearray)
{#go through the songs file, gather data
	if ($fileline =~ m/(\d{4})-(\d{2})-(\d{2});(\d{1,2}):(\d{2});(.+);(.+)/)
	{#1:year 2:month 3:day 4:hour 5:min 6:band 7:song
		$year = $1;
		$mon = $2;
		$day = $3;
		$hour = $4;
		$min = $5;
		$band = $6;
		$song = $7;
		
		if ($day != $lastday) {$days++;}
		$lastday = $day;		
		
		$allhours[$hour]++;
		
		if ($alias{$song}) { $song = $alias{$song}; }
		
		$song = substr( $song, 0, 20 );
		$song =~ s/(['|\w]+)/\u\L$1/g; #Title Case
		
		$fullsongname = "$band - $song";
		if ($band eq $inputband)
		{
			$songs{$song}++;
			$bandhours[$hour]++;
		}
	}
}

open my $ofile, '>', $topsongs;
my $i = 0;
foreach $song (sort {$fmsongs{$b} <=> $fmsongs{$a} } keys %fmsongs)
{
	$i++;
	if ($i >= $limit) {last;}
	$songs{$song} //= 0;
	print "\n$songs{$song} \t$fmsongs{$song} \t$song";
	print $ofile "\"$song\" \t".$songs{$song} / $days * 30 ." \t$fmsongs{$song}\n";
}
close $ofile;

open  my $gfile, '>', $gnuplotfile;
print $gfile <<ENDTEXT;
set terminal png size 1200, 800 enhanced
set font "arial"
set output "$station.$inputband.topsongs.png"
set grid y
set title "$station - $inputband: Top Songs (sorted by last.fm plays)"
set key top right Left width 3 height 0.5 spacing 1.5 reverse box
set xrange [:]
set yrange [0:]
set y2range [0:]
set xlabel 'Song'
set ylabel '$station Plays per 30 days'
set xtics rotate 
set style data histogram
set style histogram cluster gap 1
set style fill solid border -1
set boxwidth 0.9
plot "$topsongs" using 2:xtic(1) ti "$station", '' u 3 ti "last.fm" axes x1y2
ENDTEXT
close $gfile;
system("gnuplot $gnuplotfile");


open my $odd, '>>', 'odd.txt';
open $ofile, '>', $topsongs;
$i = 0;
foreach $song (sort {$songs{$b} <=> $songs{$a} } keys %songs)
{
	$i++;
	if ($i >= $limit) {last;}
	if ($fmsongs{$song} < 1) 
	{
		$fmsongs{$song}=0;
		print $odd "\n$inputband; $song";
	}
	print "\n$songs{$song} \t$fmsongs{$song} \t$song";
	if ($songs{$song} > 0) {
		print $ofile "\"$song\" \t".$songs{$song} / $days * 30 ." \t$fmsongs{$song}\n";
	}
}
close $ofile;

open  $gfile, '>', $gnuplotfile;
print $gfile <<ENDTEXT;
set terminal png size 1200, 800 enhanced
set font "arial"
set output "$station.$inputband.topsongs2.png"
set grid y
set title "$station - $inputband: Top Songs (sorted by radio plays)"
set key top right Left width 3 height 0.5 spacing 1.5 reverse box
set xrange [:]
set yrange [0:]
set y2range [0:]
set xlabel 'Song'
set ylabel '$station Plays per 30 days'
set xtics rotate 
set style data histogram
set style histogram cluster gap 1
set style fill solid border -1
set boxwidth 0.9
plot "$topsongs" using 2:xtic(1) ti "$station", '' u 3 ti "last.fm" axes x1y2
ENDTEXT
close $gfile;
system("gnuplot $gnuplotfile");


open $ofile, '>', $hoursfile;
$i = 0;
foreach my $playcount (@allhours)
{
	my $adjplays = ($bandhours[$i] / $allhours[$i])*100;
	print "\nHour: $i Plays: $adjplays";
	print $ofile "\n$i \t$adjplays";
	$i++;
}
close $ofile;


open  $gfile, '>', $gnuplotfile;
print $gfile <<ENDTEXT;
set terminal png size 1200, 800 enhanced
set font "arial"
set output "$station.$inputband.hours.png"
set grid y
set title "$station - $inputband: Plays per hour of the day"
set nokey
set xrange [:]
set yrange [0:]
set xlabel 'Hour'
set ylabel 'Percentage of total band plays in given hour'
set style data histogram
set style histogram cluster gap 1
set style fill solid border -1
set boxwidth 0.9
plot "$hoursfile" using 2:xtic(1) ti ""
ENDTEXT
close $gfile;
system("gnuplot $gnuplotfile");





print "\nDone\n\n";
