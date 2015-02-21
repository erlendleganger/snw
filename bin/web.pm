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

#-----------------------------------------------------------------------
my $f=$instrumentdatafile;
die "cannot find $f" if(! -f $f);
my $xml=new XML::Simple;
my $xml_instrument=$xml->XMLin($f,keyattr=>[qw(id)]);
#for my $id(keys %{$xml_gcds->{wp}}){
#$wpdb{$id}{title}=$xml_gcds->{wp}{$id}{wpTitle};
#$wpdb{$id}{status}=$xml_gcds->{wp}{$id}{wpStatus};
#$wpdb{$id}{order}=$xml_gcds->{wp}{$id}{wpOrder};
#}
print Dumper($xml_instrument->{instrument});
#print Dumper($xml_instrument);
#print Dumper(%wpdb);
#open TMP,">/tmp/wpdb.txt";
#for my $id(sort keys %wpdb){print TMP "$id,$wpdb{$id}{status}\n";}
#close TMP;

#-----------------------------------------------------------------------
$logger->trace("$me: end");
}

