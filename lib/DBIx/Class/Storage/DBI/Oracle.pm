package DBIx::Class::Storage::DBI::Oracle;

use strict;
use warnings;

use base qw/DBIx::Class::Storage::DBI/;
use mro 'c3';

sub _rebless {
    my ($self) = @_;
    
    # Default driver
    my $class = $self->_server_info->{normalized_dbms_version} <= 8
        ? 'DBIx::Class::Storage::DBI::Oracle::WhereJoins'
        : 'DBIx::Class::Storage::DBI::Oracle::Generic';

    $self->ensure_class_loaded ($class);
    bless $self, $class;
}

sub _supports_insert_returning {
  my $self = shift;

  return 1
    if $self->_server_info->{normalized_dbms_version} >= 10;

  return 0;
}

1;

=head1 NAME

DBIx::Class::Storage::DBI::Oracle - Base class for Oracle driver

=head1 DESCRIPTION

This class simply provides a mechanism for discovering and loading a sub-class
for a specific version Oracle backend. It should be transparent to the user.

For Oracle major versions <= 8 it loads the ::Oracle::WhereJoins subclass,
which unrolls the ANSI join style DBIC normally generates into entries in
the WHERE clause for compatibility purposes. To force usage of this version
no matter the database version, add

  __PACKAGE__->storage_type('::DBI::Oracle::WhereJoins');

to your Schema class.

=head1 AUTHORS

David Jack Olrik C<< <djo@cpan.org> >>

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut
