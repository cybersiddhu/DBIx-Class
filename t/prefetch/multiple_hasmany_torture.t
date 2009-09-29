use strict;
use warnings;

use Test::More;
use Test::Exception;
use lib qw(t/lib);
use DBICTest;
use IO::File;

my $schema = DBICTest->init_schema();

# $artist_rs->search(
#     {},
#     {
#         prefetch => [
#             {
#                 cds => [
#                     { tracks         => 'cd_single' },
#                     { producer_to_cd => 'producer' }
#                 ]
#             },
#             { artwork_to_artist => 'artwork' } ] );

my $cd = $schema->resultset('Artist')->create(
    {
        name => 'mo',
        rank => '1337',
        cds  => [
            {
                artist => 4,
                title  => 'Song of a Foo',
                year   => '1999',
                tracks => [
                    {
                        position => 1,
                        title    => 'Foo Me Baby One More Time',
                        cd_single =>
                          { artist => 6, title => 'MO! Single', year => 2001 }
                    },
                    {
                        position => 2,
                        title    => 'Foo Me Baby One More Time II',
                    },
                    {
                        position => 3,
                        title    => 'Foo Me Baby One More Time III',
                    },
                    {
                        position => 4,
                        title    => 'Foo Me Baby One More Time IV',
                    }
                ],
                cd_to_producer => [
                    { producer => { name => 'riba' } },
                    { producer => { name => 'sushi' } },
                ]
            },
            {
                artist => 4,
                title  => 'Song of a Foo II',
                year   => '2002',
                tracks => [
                    {
                        position => 1,
                        title    => 'Quit Playing Games With My Heart',
                        cd_single =>
                          { artist => 5, title => 'MO! Single', year => 2001 }
                    },
                    {
                        position => 2,
                        title    => 'Bar Foo',
                    },
                    {
                        position => 3,
                        title    => 'Foo Bar',
                    }
                ],
                cd_to_producer => [ { producer => 4 }, { producer => 5 }, ]
            }
        ],
        artwork_to_artist =>
          [ { artwork => { cd_id => 1 } }, { artwork => { cd_id => 2 } } ]
    }
);

my $mo = $schema->resultset('Artist')->search(
    undef,
    {
        result_class => 'DBIx::Class::ResultClass::HashRefInflator',
        prefetch     => [
            {
                cds => [
                    { tracks         => 'cd_single' },
                    { cd_to_producer => 'producer' }
                ]
            },
            { artwork_to_artist => 'artwork' }
        ]
    }
)->find(4);

is( scalar @{ $mo->{cds} }, 2, 'two CDs' );

is_deeply(
    $mo,
    {
        'cds' => [
            {
                'single_track' => undef,
                'tracks'       => [
                    {
                        'small_dt'  => undef,
                        'cd'        => '6',
                        'position'  => '1',
                        'trackid'   => '19',
                        'title'     => 'Foo Me Baby One More Time',
                        'cd_single' => {
                            'single_track' => '19',
                            'artist'       => '6',
                            'cdid'         => '7',
                            'title'        => 'MO! Single',
                            'genreid'      => undef,
                            'year'         => '2001'
                        },
                        'last_updated_on' => undef,
                        'last_updated_at' => undef
                    },
                    {
                        'small_dt'        => undef,
                        'cd'              => '6',
                        'position'        => '2',
                        'trackid'         => '20',
                        'title'           => 'Foo Me Baby One More Time II',
                        'cd_single'       => undef,
                        'last_updated_on' => undef,
                        'last_updated_at' => undef
                    },
                    {
                        'small_dt'        => undef,
                        'cd'              => '6',
                        'position'        => '3',
                        'trackid'         => '21',
                        'title'           => 'Foo Me Baby One More Time III',
                        'cd_single'       => undef,
                        'last_updated_on' => undef,
                        'last_updated_at' => undef
                    },
                    {
                        'small_dt'        => undef,
                        'cd'              => '6',
                        'position'        => '4',
                        'trackid'         => '22',
                        'title'           => 'Foo Me Baby One More Time IV',
                        'cd_single'       => undef,
                        'last_updated_on' => undef,
                        'last_updated_at' => undef
                    }
                ],
                'artist'         => '4',
                'cdid'           => '6',
                'cd_to_producer' => [
                    {
                        'attribute' => undef,
                        'cd'        => '6',
                        'producer'  => {
                            'name'       => 'riba',
                            'producerid' => '4'
                        }
                    },
                    {
                        'attribute' => undef,
                        'cd'        => '6',
                        'producer'  => {
                            'name'       => 'sushi',
                            'producerid' => '5'
                        }
                    }
                ],
                'title'   => 'Song of a Foo',
                'genreid' => undef,
                'year'    => '1999'
            },
            {
                'single_track' => undef,
                'tracks'       => [
                    {
                        'small_dt'        => undef,
                        'cd'              => '8',
                        'position'        => '2',
                        'trackid'         => '24',
                        'title'           => 'Bar Foo',
                        'cd_single'       => undef,
                        'last_updated_on' => undef,
                        'last_updated_at' => undef
                    },
                    {
                        'small_dt'        => undef,
                        'cd'              => '8',
                        'position'        => '3',
                        'trackid'         => '25',
                        'title'           => 'Foo Bar',
                        'cd_single'       => undef,
                        'last_updated_on' => undef,
                        'last_updated_at' => undef
                    },
                    {
                        'small_dt'  => undef,
                        'cd'        => '8',
                        'position'  => '1',
                        'trackid'   => '23',
                        'title'     => 'Quit Playing Games With My Heart',
                        'cd_single' => {
                            'single_track' => '23',
                            'artist'       => '5',
                            'cdid'         => '9',
                            'title'        => 'MO! Single',
                            'genreid'      => undef,
                            'year'         => '2001'
                        },
                        'last_updated_on' => undef,
                        'last_updated_at' => undef
                    }
                ],
                'artist'         => '4',
                'cdid'           => '8',
                'cd_to_producer' => [
                    {
                        'attribute' => undef,
                        'cd'        => '8',
                        'producer'  => {
                            'name'       => 'riba',
                            'producerid' => '4'
                        }
                    },
                    {
                        'attribute' => undef,
                        'cd'        => '8',
                        'producer'  => {
                            'name'       => 'sushi',
                            'producerid' => '5'
                        }
                    }
                ],
                'title'   => 'Song of a Foo II',
                'genreid' => undef,
                'year'    => '2002'
            }
        ],
        'artistid'          => '4',
        'charfield'         => undef,
        'name'              => 'mo',
        'artwork_to_artist' => [
            {
                'artwork'       => { 'cd_id' => '1' },
                'artist_id'     => '4',
                'artwork_cd_id' => '1'
            },
            {
                'artwork'       => { 'cd_id' => '2' },
                'artist_id'     => '4',
                'artwork_cd_id' => '2'
            }
        ],
        'rank' => '1337'
    }
);

done_testing;
