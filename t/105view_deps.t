#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use lib qw(t/lib);
use ViewDeps;
use Devel::Dwarn;
use Data::Dumper;
use Carp::Always;

BEGIN {
    #$ENV{DBIC_TRACE} = 1;
    use_ok('DBIx::Class::ResultSource::View');
}

#################### SANITY

my $view = DBIx::Class::ResultSource::View->new( { name => 'Quux' } );

isa_ok( $view, 'DBIx::Class::ResultSource', 'A new view' );
isa_ok( $view, 'DBIx::Class', 'A new view also' );

can_ok( $view, $_ ) for qw/new from deploy_depends_on/;

#################### DEPS

#if (-e "t/var/viewdeps.db") {
#ok(unlink("t/var/viewdeps.db"),"Deleted old DB OK");
#}

my @sql_files = glob("t/sql/ViewDeps*.sql");
for (@sql_files) {
    ok( unlink($_), "Deleted old SQL $_ OK" );
}

my $schema = ViewDeps->connect( 'dbi:SQLite:dbname=t/var/viewdeps.db',
    { quote_char => '"', } );
ok( $schema, 'Connected to ViewDeps schema OK' );

my $deps_ref = {
    map {
        $schema->resultset($_)->result_source->name =>
            $schema->resultset($_)->result_source->deploy_depends_on
        }
        grep {
        $schema->resultset($_)
            ->result_source->isa('DBIx::Class::ResultSource::View')
        } @{ [ $schema->sources ] }
};

#diag( Dwarn $deps_ref);

my @sorted_sources = sort {
    keys %{ $deps_ref->{$a} || {} } <=> keys %{ $deps_ref->{$b} || {} }
        || $a cmp $b
    }
    keys %$deps_ref;

#diag( Dwarn @sorted_sources );

#################### DEPLOY

my $ddl_dir = "t/sql";
$schema->create_ddl_dir( [ 'PostgreSQL', 'MySQL', 'SQLite' ], 0.1, $ddl_dir );

ok( -e $_, "$_ was created successfully" ) for @sql_files;

$schema->deploy( { add_drop_table => 1 } );

#################### DOES ORDERING WORK?

my $tr = $schema->{sqlt};
#diag("My TR isa: ", ref $tr);
#diag( Dwarn keys %{$tr->{views}});
my @keys = keys %{$tr->{views}};


my @sqlt_sources = 
sort {
    $tr->{views}->{$a}->{order} cmp $tr->{views}->{$b}->{order}
}
@keys;

#diag(Dwarn @sqlt_sources);

is_deeply(\@sorted_sources,\@sqlt_sources,"SQLT view order triumphantly matches our order.");

done_testing;