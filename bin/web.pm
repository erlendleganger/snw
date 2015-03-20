package web;
use strict;
use warnings;
use Log::Log4perl qw(:easy);
use Data::Dumper;
$Data::Dumper::Indent=1;
use XML::Simple;
use File::Copy;
#use Text::Template qw(fill_in_file);
#use XML::Parser::Expat;
#use Time::Piece;
#use Time::Seconds;
#use SVG::TT::Graph::BarHorizontal;
#use POSIX;
our $VERSION="0.1";
use base "Exporter";
our @EXPORT=qw(hello);
my $instrumentdatafile="$ENV{LIB_DATADIR}/writing-instrument.xml";
my $mediumdatafile="$ENV{LIB_DATADIR}/writing-medium.xml";
my $manufacturerdatafile="$ENV{LIB_DATADIR}/manufacturer.xml";
my $vendordatafile="$ENV{LIB_DATADIR}/vendor.xml";
my $gendir="$ENV{WEB_GENDIR}";
my $docsrcdir=qq($ENV{WEB_DOCPADDIR}/src/document);
my $topicdir=qq($ENV{LIB_TOPICDIR});
my $genwarning=qq($ENV{LIB_GENWARN});
my $econoop=qq(<!-- noop eco to avoid warning about eco rendering not producing output: -->
<% noop=1 %>);

#-----------------------------------------------------------------------
my %pentype;
$pentype{ball}{gel}="Rollerball gel";
$pentype{ball}{oil}="Ballpoint";
$pentype{ball}{water}="Rollerball";
$pentype{fibre}{liquid}="Fibre";
$pentype{nib}{m}="Fountain pen";

#-----------------------------------------------------------------------
#set up logging
#use DEBUG to debug, INFO||ERROR||FATAL for normal operations;
my $loglevel;
$loglevel=$FATAL;
$loglevel=$DEBUG;
$loglevel=$TRACE;
$loglevel=$INFO;
#Log::Log4perl->easy_init($loglevel);
#my $log=get_logger();

use Log::Log4perl qw(get_logger);
        
my $conf = qq(
#FATAL,ERROR,WARN,INFO,DEBUG,TRACE
log4perl.category.Bar.Twix         = TRACE, Logfile
log4perl.appender.Logfile          = Log::Log4perl::Appender::File
log4perl.appender.Logfile.filename = $ENV{LIB_LOGDIR}/test.log
log4perl.appender.Logfile.layout = \\
Log::Log4perl::Layout::PatternLayout
log4perl.appender.Logfile.layout.ConversionPattern = %d %F{1} %L: %m %n
);
Log::Log4perl::init(\$conf);
my $logger = get_logger("Bar::Twix");

#-----------------------------------------------------------------------
#-----------------------------------------------------------------------
sub convert_db{
   convert_pen();
   convert_medium();
   convert_loadout();
}

#-----------------------------------------------------------------------
#-----------------------------------------------------------------------
sub convert_loadout{
my $me="convert_loadout";
$logger->trace("$me: start");

#-----------------------------------------------------------------------
opendir DIR,$topicdir or die "cannot open $topicdir";
while(my $f=readdir DIR){
   if($f=~m/loadout-(.*?)\./){
      my $date=$1;
      my $text;

      #------------------------------------------------------------------
      #get loadout text from file
      {
         open IN,"<$topicdir/$f" or die "cannot open $f";
         {local $/=undef;$text =<IN>;}
         close IN;
      }

      #-----------------------------------------------------------------
      my $outfname="$docsrcdir/handwriting/$f.eco";
      open OUT,">$outfname" or die "cannot create $outfname";
      print OUT<<EOT
---
#$genwarning
layout: post
type: handwriting
category: loadout
title: Loadout $date
date: $date
---

$text
EOT
      ;
      close OUT;
   }
}
closedir DIR;

#-----------------------------------------------------------------------
$logger->trace("$me: end");
}

#-----------------------------------------------------------------------
#-----------------------------------------------------------------------
sub convert_medium{
my $me="convert_medium";
#my ($id)=@_;
$logger->trace("$me: start");
#$logger->trace("$me: id=$id");
my $xml=new XML::Simple;
my $f;
my $reviewtemplatefile="$ENV{LIB_MISCDIR}/tpl-medium-review.md";

#-----------------------------------------------------------------------
$f=$mediumdatafile;
die "cannot find $f" if(! -f $f);
my $xml_medium=$xml->XMLin($f,keyattr=>[qw(id)]);
open TMP,">/tmp/medium.txt"; print TMP Dumper($xml_medium->{medium});close TMP;

#-----------------------------------------------------------------------
$f=$manufacturerdatafile;
die "cannot find $f" if(! -f $f);
my $xml_manufacturer=$xml->XMLin($f,keyattr=>[qw(id)]);
open TMP,">/tmp/manufacturer.txt"; print TMP Dumper($xml_manufacturer->{manufacturer});close TMP;

#-----------------------------------------------------------------------
$f=$vendordatafile;
die "cannot find $f" if(! -f $f);
my $xml_vendor=$xml->XMLin($f,keyattr=>[qw(id)]);
open TMP,">/tmp/vendor.txt"; print TMP Dumper($xml_vendor->{vendor});close TMP;

#-----------------------------------------------------------------------
for my $id(keys %{$xml_medium->{medium}}){

   #--------------------------------------------------------------------
   my $manufacturerid=$xml_medium->{medium}{$id}{manufacturer}{id};
   my $manufacturer=$xml_manufacturer->{manufacturer}{$manufacturerid}{name};
   my $vendorid=$xml_medium->{medium}{$id}{procurement}{vendor}{id};
   my $vendor=$xml_vendor->{vendor}{$vendorid}{name};
   my $name=$xml_medium->{medium}{$id}{name};
   my $fname="$docsrcdir/handwriting/$id.html.md";
   my $reviewfname="$topicdir/$id.md";
   my $reviewtext=$xml_medium->{medium}{$id}{review}{text};
   $logger->trace("$manufacturerid|$manufacturer|$vendorid|$vendor|$name");

   #--------------------------------------------------------------------
   #create sample review text if new item
   if (! -f $reviewfname){
      copy $reviewtemplatefile, $reviewfname or die "cannot create $reviewfname from template";
   }
   
   #--------------------------------------------------------------------
   #get review text from file
   if (-f $reviewfname){
      open IN,"<$reviewfname" or die "cannot open $reviewfname";
      {local $/=undef;$reviewtext =<IN>;}
      close IN;
   }

   #--------------------------------------------------------------------
   open OUT,">$fname" or die "cannot create $fname";
   print OUT<<EOT
---
#$genwarning
layout: post
type: handwriting
category: mediumreview
title: Review of $name
titleshort: $name
date: $xml_medium->{medium}{$id}{review}{date}
docid: $id
---

* Manufacturer: [$manufacturer](/a/b/c/$manufacturerid.html)
* Name: $name
* Review date: $xml_medium->{medium}{$id}{review}{date}

$reviewtext
EOT
;
   close OUT;
}

#-----------------------------------------------------------------------
$logger->trace("$me: end");
}

#-----------------------------------------------------------------------
#-----------------------------------------------------------------------
sub convert_pen{
my $me="convert_pen";
$logger->trace("$me: start");
my $reviewtemplatefile="$ENV{LIB_MISCDIR}/tpl-pen-review.md";
my $xml=new XML::Simple;
my $f;

#-----------------------------------------------------------------------
$f=$instrumentdatafile;
die "cannot find $f" if(! -f $f);
my $xml_instrument=$xml->XMLin($f,keyattr=>[qw(id)]);
open TMP,">/tmp/instrument.txt"; print TMP Dumper($xml_instrument->{instrument});close TMP;

#-----------------------------------------------------------------------
$f=$manufacturerdatafile;
die "cannot find $f" if(! -f $f);
my $xml_manufacturer=$xml->XMLin($f,keyattr=>[qw(id)]);
open TMP,">/tmp/manufacturer.txt"; print TMP Dumper($xml_manufacturer->{manufacturer});close TMP;

#-----------------------------------------------------------------------
$f=$vendordatafile;
die "cannot find $f" if(! -f $f);
my $xml_vendor=$xml->XMLin($f,keyattr=>[qw(id)]);
open TMP,">/tmp/vendor.txt"; print TMP Dumper($xml_vendor->{vendor});close TMP;

#-----------------------------------------------------------------------
for my $id(keys %{$xml_instrument->{instrument}}){

   #--------------------------------------------------------------------
   my $manufacturerid=$xml_instrument->{instrument}{$id}{manufacturer}{id};
   my $manufacturer=$xml_manufacturer->{manufacturer}{$manufacturerid}{name};
   my $vendorid=$xml_instrument->{instrument}{$id}{procurement}{vendor}{id};
   my $vendor=$xml_vendor->{vendor}{$vendorid}{name};
   my $name=$xml_instrument->{instrument}{$id}{name};
   my $tip=$xml_instrument->{instrument}{$id}{tip};
   my $ink=$xml_instrument->{instrument}{$id}{ink};
   my $fname="$docsrcdir/handwriting/$id.html.md.eco";
   my $reviewfname="$topicdir/$id.md";
   my $reviewtext=$xml_instrument->{instrument}{$id}{review}{text};
   $logger->trace("$manufacturerid|$manufacturer|$vendorid|$vendor|$name|$tip|$ink");

   #--------------------------------------------------------------------
   my $pentype;
   if(!defined $pentype{$tip}{$ink}){
      $logger->fatal("cannot find pentype for $id, $tip, $ink");
      exit 1;
   }

   #--------------------------------------------------------------------
   #create sample review text if new item
   if (! -f $reviewfname){
      copy $reviewtemplatefile, $reviewfname or die "cannot create $reviewfname from template";
   }
   
   #--------------------------------------------------------------------
   #get review text from file
   if (-f $reviewfname){
      open IN,"<$reviewfname" or die "cannot open $reviewfname";
      {local $/=undef;$reviewtext =<IN>;}
      close IN;
   }

   #--------------------------------------------------------------------
   #get review text from file
   if (-f $reviewfname){
      open IN,"<$reviewfname" or die "cannot open $reviewfname";
      {local $/=undef;$reviewtext =<IN>;}
      close IN;
   }

   #--------------------------------------------------------------------
   open OUT,">$fname" or die "cannot create $fname";
   print OUT<<EOT
---
#$genwarning
layout: post
type: handwriting
category: penreview
title: Review of $name
titleshort: $name
date: $xml_instrument->{instrument}{$id}{review}{date}
docid: $id
---
* Manufacturer: [$manufacturer](/a/b/c/$manufacturerid.html)
* Name: $name
* Type: $pentype{$tip}{$ink}
* Weight: $xml_instrument->{instrument}{$id}{weight}{total}g
* Review date: $xml_instrument->{instrument}{$id}{review}{date}

$econoop
$reviewtext
EOT
;
   close OUT;
}

#-----------------------------------------------------------------------
my @db;
for my $id(keys %{$xml_instrument->{instrument}}){
   my $manufacturerid=$xml_instrument->{instrument}{$id}{manufacturer}{id};
   my $manufacturer=$xml_manufacturer->{manufacturer}{$manufacturerid}{name};
   my $name=$xml_instrument->{instrument}{$id}{name};
   push @db,qq($manufacturer $name);
}
my $fname="$gendir/pen-list.txt";
open OUT,">$fname" or die("cannot create $fname");
print OUT "#list of pens\n";
print OUT join "\n", sort @db;
print OUT "\n";
close OUT;

#-----------------------------------------------------------------------
$logger->trace("$me: end");
}

