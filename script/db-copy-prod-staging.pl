#! /software/bin/perl

##
## Script to transfer the data from the production database 
## into the staging database.
##

use strict;
use warnings;

use YAML;
use Cwd 'abs_path';
use File::Basename;
use File::Temp qw(tempdir);
use Data::Dumper;

## Read in configuration

my $SCRIPT_DIR = dirname( abs_path($0) );
my $DBCONF     = YAML::LoadFile("$SCRIPT_DIR/../config/database.yml") or die "Unable to read database.yml";

## Move into a temp dir so we can dump files and go about our bussiness

my $TMPDIR = tempdir( CLEANUP => 1 );
chdir($TMPDIR);

## Database connections

my $prod_db   = $DBCONF->{production}->{database};
my $prod_host = $DBCONF->{production}->{host};
my $prod_port = $DBCONF->{production}->{port};
my $prod_user = $DBCONF->{production}->{username};
my $prod_pass = $DBCONF->{production}->{password};

my $stag_db   = $DBCONF->{staging}->{database};
my $stag_host = $DBCONF->{staging}->{host};
my $stag_port = $DBCONF->{staging}->{port};
my $stag_user = $DBCONF->{staging}->{username};
my $stag_pass = $DBCONF->{staging}->{password};

## Do some dumping and slurping...

print "- running mysqldump\n";
system("mysqldump --opt --no-create-db -h $prod_host -P $prod_port --user=$prod_user --password=$prod_pass --databases $prod_db > dumpfile.sql");

print "- optimising import\n";

open ORIG_FILE, "dumpfile.sql"   or die $!;
open PROC_FILE, ">dumpfile2.sql" or die $!;

print PROC_FILE "SET AUTOCOMMIT = 0;\nSET FOREIGN_KEY_CHECKS=0;\n";
while (<ORIG_FILE>) { print PROC_FILE $_; }
print PROC_FILE "SET FOREIGN_KEY_CHECKS = 1;\nCOMMIT;\nSET AUTOCOMMIT = 1;\n";

close ORIG_FILE;
close PROC_FILE;

print "- running import\n";
system("mysql -h $stag_host -P $stag_port --user=$stag_user --password=$stag_pass $stag_db < dumpfile2.sql");

## Finish off...

$production_dbh->disconnect();
$staging_dbh->disconnect();
chdir($SCRIPT_DIR);

exit;
