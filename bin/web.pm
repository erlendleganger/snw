package web;
use strict;
use warnings;
use Log::Log4perl qw(:easy);
use Data::Dumper;
$Data::Dumper::Indent=1;
use XML::Simple;
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
my $manufacturerdatafile="$ENV{LIB_DATADIR}/manufacturer.xml";
my $vendordatafile="$ENV{LIB_DATADIR}/vendor.xml";
#export WEB_DOCPADDIR=$LIB_BASEDIR/docpad
my $docsrcdir=qq($ENV{WEB_DOCPADDIR}/src/document);
my $topicdir=qq($ENV{LIB_TOPICDIR});
my $genwarning="generated file, all manual updates will be lost";

#-----------------------------------------------------------------------
my %pentype;
$pentype{ball}{gel}="Rollerball gel";
$pentype{ball}{oil}="Ballpoint";
$pentype{ball}{water}="Rollerball";

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
my $me="convert_db";
my ($id)=@_;
$logger->trace("$me: start");
$logger->trace("$me: id=$id");
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
   my $fname="$docsrcdir/handwriting/$id.html.md";
   my $reviewfname="$topicdir/$id.md";
   my $reviewtext=$xml_instrument->{instrument}{$id}{review}{text};
   $logger->trace("$manufacturer|$name|$vendor|$tip|$ink");

   #--------------------------------------------------------------------
   my $pentype;
   if(!defined $pentype{$tip}{$ink}){
      $logger->fatal("cannot find pentype for $id, $tip, $ink");
      exit 1;
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
category: review
title: $manufacturer $name
date: $xml_instrument->{instrument}{$id}{review}{date}
---

* Manufacturer: [$manufacturer](/a/b/c/$manufacturerid.html)
* Name: $name
* Type: $pentype{$tip}{$ink}
* Weight: $xml_instrument->{instrument}{$id}{weight}{total}g

$reviewtext
EOT
;
   close OUT;
}

#-----------------------------------------------------------------------
$logger->trace("$me: end");
}

