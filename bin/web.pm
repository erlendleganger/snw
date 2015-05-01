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
my $itemdatafile="$ENV{LIB_DATADIR}/writing-item.xml";
my $manufacturerdatafile="$ENV{LIB_DATADIR}/manufacturer.xml";
my $vendordatafile="$ENV{LIB_DATADIR}/vendor.xml";
my $gendir="$ENV{WEB_GENDIR}";
my $docsrcdir=qq($ENV{WEB_DOCPADDIR}/src/document);
my $topicdir=qq($ENV{LIB_TOPICDIR});
my $genwarning=qq($ENV{LIB_GENWARN});
my $econoop=qq(<!-- noop eco to avoid warning about eco rendering not producing output: -->
<% noop=1 %>);
my $defaultreviewstatus="queued";

#-----------------------------------------------------------------------
my %pentype;
$pentype{ball}{gel}="Rollerball gel";
$pentype{ball}{oil}="Ballpoint";
$pentype{ball}{water}="Rollerball";
$pentype{fibre}{liquid}="Fibre";
$pentype{fibre}{pigment}="Fibre"; #felt, for the uni pin pen
$pentype{nib}{m}="Fountain pen";
$pentype{nib}{f}="Fountain pen";
$pentype{graphite}{black}="Pencil";

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
   convert_item();
}

#-----------------------------------------------------------------------
#-----------------------------------------------------------------------
sub convert_loadout{
my $me="convert_loadout";
$logger->trace("$me: start");

#-----------------------------------------------------------------------
my $loadoutdir="$topicdir/loadout";
opendir DIR,$loadoutdir or die "cannot open $loadoutdir";
while(my $f=readdir DIR){
   if($f=~m/loadout-(.*?)\./){
      my $date=$1;
      my $text;

      #------------------------------------------------------------------
      #get loadout text from file
      {
         open IN,"<$loadoutdir/$f" or die "cannot open $f";
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
sub convert_item{
my $me="convert_item";
#my ($id)=@_;
$logger->trace("$me: start");
#$logger->trace("$me: id=$id");
my $xml=new XML::Simple;
my $f;
my $reviewtemplatefile="$ENV{LIB_MISCDIR}/tpl-item-review.md";

#-----------------------------------------------------------------------
$f=$itemdatafile;
die "cannot find $f" if(! -f $f);
my $xml_item=$xml->XMLin($f,keyattr=>[qw(id)]);
open TMP,">/tmp/item.txt"; print TMP Dumper($xml_item->{item});close TMP;

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
for my $id(keys %{$xml_item->{item}}){

   #--------------------------------------------------------------------
   my $manufacturerid=$xml_item->{item}{$id}{manufacturer}{id};
   my $manufacturer=$xml_manufacturer->{manufacturer}{$manufacturerid}{name};
   my $vendorid=$xml_item->{item}{$id}{procurement}{vendor}{id};
   my $vendor=$xml_vendor->{vendor}{$vendorid}{name};
   my $name=$xml_item->{item}{$id}{name};
   my $fname="$docsrcdir/handwriting/$id.html.md.eco";
   my $reviewfname="$topicdir/item/$id.md";
   my $reviewdate=$xml_item->{item}{$id}{review}{date};
   $logger->trace("$manufacturerid|$vendorid|$name|$reviewdate");

   #--------------------------------------------------------------------
   #create sample review text if new item
   if (! -f $reviewfname){
      copy $reviewtemplatefile, $reviewfname or die "cannot create $reviewfname from template $reviewtemplatefile";
   }
   
   #--------------------------------------------------------------------
   #get review text from file
   my $reviewtext;
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
category: item
title: $name
titleshort: $name
docid: $id
date: $reviewdate
---
* Manufacturer: [$manufacturer](/a/b/c/$manufacturerid.html)
* Name: $name
* Date: $reviewdate

$econoop
$reviewtext
EOT
;
   close OUT;
}

#-----------------------------------------------------------------------
my $fname="$gendir/item-links.txt";
open OUT,">$fname" or die("cannot create $fname");
print OUT "#list of item links\n";
for my $id(sort keys %{$xml_item->{item}}){
   print OUT "<%- \@getPostLink('$id') %>\n";
}
close OUT;

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
   my $fname="$docsrcdir/handwriting/$id.html.md.eco";
   my $reviewfname="$topicdir/medium/$id.md";
   my $reviewdate=$xml_medium->{medium}{$id}{review}{date};
   my $reviewtext=$xml_medium->{medium}{$id}{review}{text};
   my $pagecount=$xml_medium->{medium}{$id}{pagecount};
   my $paper=$xml_medium->{medium}{$id}{paper};
   my $ruling=$xml_medium->{medium}{$id}{ruling};
   my $size=$xml_medium->{medium}{$id}{size};
   $logger->trace("$manufacturerid|$vendorid|$name|$reviewdate");

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
docid: $id
date: $reviewdate
---
* Manufacturer: [$manufacturer](/a/b/c/$manufacturerid.html)
* Name: $name
* Paper: $paper
* Size: $size
* Ruling: $ruling
* Page count: $pagecount
* Review date: $reviewdate

$econoop
$reviewtext
EOT
;
   close OUT;
}

#-----------------------------------------------------------------------
my $fname="$gendir/medium-links.txt";
open OUT,">$fname" or die("cannot create $fname");
print OUT "#list of medium links\n";
for my $id(sort keys %{$xml_medium->{medium}}){
   print OUT "<%- \@getPostLink('$id') %>\n";
}
close OUT;

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
   my $weightunit=$xml_instrument->{instrument}{$id}{weight}{total}{unit};
   my $weighttotal=$xml_instrument->{instrument}{$id}{weight}{total}{content};
   my $fname="$docsrcdir/handwriting/$id.html.md.eco";
   my $reviewfname="$topicdir/instrument/$id.md";
   my $reviewtext=$xml_instrument->{instrument}{$id}{review}{text};
   my $reviewdate=$xml_instrument->{instrument}{$id}{review}{date};
   my $reviewstatus=$xml_instrument->{instrument}{$id}{review}{status}||$defaultreviewstatus;
   $logger->trace("$manufacturerid|$vendorid|$name|$tip|$ink|$reviewdate");

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
date: $reviewdate
docid: $id
status: $reviewstatus
---
* Manufacturer: [$manufacturer](/a/b/c/$manufacturerid.html)
* Name: $name
* Type: $pentype{$tip}{$ink}
* Weight: $weighttotal$weightunit
* Review date: $reviewdate

$econoop
$reviewtext
EOT
;
   close OUT;
}

#-----------------------------------------------------------------------
my $fname="$gendir/pen-names.txt";
open OUT,">$fname" or die("cannot create $fname");
print OUT "#list of pens\n";
for my $id(
   sort{$xml_instrument->{instrument}{$a}{name} cmp $xml_instrument->{instrument}{$b}{name}} keys %{$xml_instrument->{instrument}}){
   print OUT "$xml_instrument->{instrument}{$id}{name}\n";
}
close OUT;

#-----------------------------------------------------------------------
$fname="$gendir/pen-links.txt";
open OUT,">$fname" or die("cannot create $fname");
print OUT "#list of pen links\n";
for my $id(sort keys %{$xml_instrument->{instrument}}){
   print OUT "<%- \@getPostLink('$id') %>\n";
}
close OUT;

#-----------------------------------------------------------------------
$logger->trace("$me: end");
}

