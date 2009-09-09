use strict;
use warnings;  

use Test::More;
use lib qw(t/lib);
use DBICTest;

my ($dsn, $user, $pass) = @ENV{map { "DBICTEST_DB2_${_}" } qw/DSN USER PASS/};

#warn "$dsn $user $pass";

plan skip_all => 'Set $ENV{DBICTEST_DB2_DSN}, _USER and _PASS to run this test'
  unless ($dsn && $user);

plan tests => 9;

my $schema = DBICTest::Schema->connect($dsn, $user, $pass);

my $dbh = $schema->storage->dbh;

eval { $dbh->do("DROP TABLE artist") };

$dbh->do("CREATE TABLE artist (artistid INTEGER GENERATED BY DEFAULT AS IDENTITY (START WITH 1, INCREMENT BY 1), name VARCHAR(255), charfield CHAR(10), rank INTEGER DEFAULT 13);");

# This is in core, just testing that it still loads ok
$schema->class('Artist')->load_components('PK::Auto');

my $ars = $schema->resultset('Artist');

# test primary key handling
my $new = $ars->create({ name => 'foo' });
ok($new->artistid, "Auto-PK worked");

my $init_count = $ars->count;
for (1..6) {
    $ars->create({ name => 'Artist ' . $_ });
}
is ($ars->count, $init_count + 6, 'Simple count works');

# test LIMIT support
my $it = $ars->search( {},
  {
    rows => 3,
    order_by => 'artistid'
  }
);
is( $it->count, 3, "LIMIT count ok" );

my @all = $it->all;
is (@all, 3, 'Number of ->all objects matches count');

$it->reset;
is( $it->next->name, "foo", "iterator->next ok" );
is( $it->next->name, "Artist 1", "iterator->next ok" );
is( $it->next->name, "Artist 2", "iterator->next ok" );
is( $it->next, undef, "next past end of resultset ok" );  # this can not succeed if @all > 3


my $test_type_info = {
    'artistid' => {
        'data_type' => 'INTEGER',
        'is_nullable' => 0,
        'size' => 10
    },
    'name' => {
        'data_type' => 'VARCHAR',
        'is_nullable' => 1,
        'size' => 255
    },
    'charfield' => {
        'data_type' => 'CHAR',
        'is_nullable' => 1,
        'size' => 10 
    },
    'rank' => {
        'data_type' => 'INTEGER',
        'is_nullable' => 1,
        'size' => 10 
    },
};


my $type_info = $schema->storage->columns_info_for('artist');
is_deeply($type_info, $test_type_info, 'columns_info_for - column data types');

# clean up our mess
END {
    my $dbh = eval { $schema->storage->_dbh };
    $dbh->do("DROP TABLE artist") if $dbh;
}
