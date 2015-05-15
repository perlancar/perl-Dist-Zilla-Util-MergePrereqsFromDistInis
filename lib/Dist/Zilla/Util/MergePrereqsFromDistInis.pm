package Dist::Zilla::Util::MergePrereqsFromDistInis;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(parse_prereqs_from_dist_ini);

our %SPEC;

$SPEC{merge_prereqs_from_dist_ini} = {
    v => 1.1,
    summary => "Merge prereqs from several dzil dist.ini's",
    description => <<'_',

This routine tries to merge prereqs from several Dist::Zilla's `dist.ini`
files.

An application of this routine is for `Dist::Zilla::Plugin::MergeDists`.

_
    args_rels => {
        req_one => [qw/paths srcs/],
    },
    args => {
        paths => {
            summary => "Paths to dist.ini's",
            schema => ['array*', of=>'str*', min_len=>1],
            'x.schema.element_entity' => 'filename',
        },
        srcs => {
            summary => "Content of dist.ini's",
            schema => ['array*', of=>'str*', min_len=>1],
        },
    },
    result_naked => 1,
};
sub merge_prereqs_from_dist_inis {
    require Dist::Zilla::Util::ParsePrereqsFromDistIni;

    my %args = @_;

    my $reader = Config::IOD::Reader->new(
        ignore_unknown_directive => 1,
    );

    my @prereqs_list;
    if ($args{paths}) {
        push @prereqs_list, Dist::Zilla::Util::ParsePrereqsFromDistIni::parse_prereqs_from_dist_ini(path=>$_)
            for @{$args{paths}};
    } else {
        push @prereqs_list, Dist::Zilla::Util::ParsePrereqsFromDistIni::parse_prereqs_from_dist_ini(src=>$_)
            for @{$args{srcs}};
    }

    return $prereqs_list[0] if @prereqs_list == 1;

    # merge the keys
    my $res;
    for my $prereqs (@prereqs_list) {
        for my $phase (keys %$prereqs) {
            my $phase_prereqs = $prereqs->{$phase};
            for my $rel (keys %$phase_prereqs) {
                my $mods = $phase_prereqs->{$rel};
                for my $mod (keys %$mods) {
                    $res->{$phase}{$rel}{$mod} = $mods->{$mod};
                }
            }
        }
    }

    # upgrade suggests to recommends/requires
    for my $phase (keys %$res) {
        my $phase_res = $res->{$phase};
        my $suggests = $phase_res->{suggests} or next;
        for my $mod (keys %$suggests) {
            delete $suggests->{$mod} if $res->{$phase}{recommends}{$mod};
            delete $suggests->{$mod} if $res->{$phase}{requires}{$mod};
        }
    }

    # upgrade recommends to requires
    for my $phase (keys %$res) {
        my $phase_res = $res->{$phase};
        my $recommends = $phase_res->{recommends} or next;
        for my $mod (keys %$recommends) {
            delete $recommends->{$mod} if $res->{$phase}{requires}{$mod};
        }
    }

    $res;
}

1;
# ABSTRACT:

=head1 SYNOPSIS

 use Dist::Zilla::Util::MergePrereqsFromDistInis qw(merge_prereqs_from_dist_inis);

 my $merged_prereqs = merge_prereqs_from_dist_inis(paths => ["../Dist1/dist.ini", "../Dist2/dist.ini"]);


=head1 DESCRIPTION

This module provides C<merge_prereqs_from_dist_inis()>.


=head1 SEE ALSO

L<Dist::Zilla>
