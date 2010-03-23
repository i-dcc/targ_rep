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
use DBI;
use DBD::mysql;
use IO::File;
use Text::CSV_XS;
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

my $production_dbh = DBI->connect(
  "dbi:mysql:database=$prod_db;host=$prod_host;port=$prod_port", $prod_user, $prod_pass,
  { RaiseError => 1, AutoCommit => 0, FetchHashKeyName => "NAME_lc" }
) or die "Cannot connect to production db! $!";

my $stag_db   = $DBCONF->{staging}->{database};
my $stag_host = $DBCONF->{staging}->{host};
my $stag_port = $DBCONF->{staging}->{port};
my $stag_user = $DBCONF->{staging}->{username};
my $stag_pass = $DBCONF->{staging}->{password};

my $staging_dbh = DBI->connect(
  "dbi:mysql:database=$stag_db;host=$stag_host;port=$stag_port", $stag_user, $stag_pass,
  { RaiseError => 1, AutoCommit => 1, FetchHashKeyName => "NAME_lc" }
) or die "Cannot connect to staging db! $!";

## Do some dumping and slurping...

my @tables = qw/
  audits
  schema_migrations
  users
  pipelines
  molecular_structures
  targeting_vectors
  es_cells
/;

print "truncating tables...\n";
truncate_tables( $staging_dbh, \@tables );

print "dumping and transferring data...\n";
foreach my $table ( @tables ) {
  print " - $table\n";
  my $cols = get_column_names( $production_dbh, $table );
  my $data = fetch_all( $production_dbh, $table, $cols );
  dump_all( $table, $data, $cols );
  import_csv( $staging_dbh, $table, $cols );
  check_transfer( $production_dbh, $staging_dbh, $table, $table );
}

##
## Now finally, transfer the genbank_files table using MySQL dump, 
## as the CSV export/import removes all the newline characters and 
## corrupts the formatting.
##

system("mysqldump -h $prod_host -P $prod_port -u $prod_user --password=$prod_pass --no-create-db $prod_db genbank_files > genbank_files.sql");
truncate_tables( $staging_dbh, ["genbank_files"] );
system("mysql -h $stag_host -P $stag_port -u $stag_user --password=$stag_pass $stag_db < genbank_files.sql");

## Finish off...

$production_dbh->disconnect();
$staging_dbh->disconnect();
chdir($SCRIPT_DIR);

exit;

##
## Subroutines...
##

sub truncate_tables {
  my ( $dbh, $tables ) = @_;
  for my $table ( reverse(@{$tables}) ) { $dbh->do("truncate $table"); }
}

sub get_column_names {
  my ( $dbh, $table ) = @_;
  
  my $sth = $dbh->prepare("select * from $table");
  $sth->execute();
  
  my $row = $sth->fetchrow_hashref();
  my $columns = [ keys %{$row} ];
  $sth->finish;
  
  return $columns;
}

sub fetch_all {
  my ( $dbh, $table, $columns ) = @_;
  
  my $sth = $dbh->prepare( 'SELECT ' . join(',',@{$columns}) . ' FROM ' . $table );
  $sth->execute();
  my $data = $sth->fetchall_arrayref;
  $sth->finish();
  
  return $data;
}

sub dump_all {
  my ( $filename, $data, $columns ) = @_;
  
  my $file = $filename . '.csv';
  my $fh = new IO::File;
  my $csv = Text::CSV_XS->new({ always_quote => 1 });
  
  if ($fh->open(">$file")) {
    # Print the headers
    if ($csv->print($fh, $columns)) { print $fh "\n"; }
    else {
      die "Error writing to file: $file for the header line: \n" . Dumper($columns);
    }
    
    foreach my $row ( @{$data} ) {
      # Strip newline characters from data entries and enter NULL if 
      # we need to insert a NULL value...
      my $clean_row = [];
      foreach my $column ( @{$row} ) {
        if ( $column ) { $column =~ s/\s+/ /g; }
        else           { $column = "foobarweewarneenarwibbleflipblip"; }
        push( @{$clean_row}, $column );
      }
      
      # Print the data row to file
      my $line = "";
      if ($csv->combine(@{$clean_row})) { $line = $csv->string(); }
      else                              { die "Error writing row!\n".$csv->error_input()."\n".Dumper($clean_row)."\n" }
      $line =~ s/"foobarweewarneenarwibbleflipblip"/NULL/g;
      print $fh "$line\n";
    }
    $fh->close;
  }
  else {
    die "Unable to create file: $file";
  }
}

sub import_csv {
  my ( $dbh, $table, $columns ) = @_;
  
  my $sql = q[
    load data local infile ']. $table .q[.csv' into table ]. $table .q[
    fields terminated by ',' optionally enclosed by '"'
    lines terminated by '\n'
    ignore 1 lines
    (
  ] . join(',',@{$columns}) .
  q[
    )
  ];
  
  my $sth = $dbh->prepare( $sql );
  
  $sth->execute();
  $sth->finish();
}

sub check_transfer {
  my ( $ori_dbh, $new_dbh, $ori_table, $new_table ) = @_;
  
  my $ori_query = "select count(*) from $ori_table";
  my $new_query = "select count(*) from $new_table";
  
  my $ori_sth = $ori_dbh->prepare( $ori_query ); $ori_sth->execute();
  my $new_sth = $new_dbh->prepare( $new_query ); $new_sth->execute();
  
  my $ori_count = $ori_sth->fetchall_arrayref->[0]->[0];
  my $new_count = $new_sth->fetchall_arrayref->[0]->[0];
  
  if ( $ori_count != $new_count ) {
    die "Transfer of $ori_table did not succeed! Found $new_count rows, but expected $ori_count.";
  }
}
