package Test2::Plugin::MakeFailedTestTODO;
use 5.008001;
use strict;
use warnings;

use PPI;
use Test2::API qw(
    test2_add_callback_post_load
    test2_stack
);

our $VERSION = "0.01";

my $loaded;
my $ppi_cache = +{};

sub import {
    my ($class) = @_;
    return if $loaded++;

    test2_add_callback_post_load(sub {
        my $hub = test2_stack()->top;
        $hub->listen(\&listener, inherit => 1);
    });
}

sub listener {
    my ($hub, $event) = @_;

    return unless $event->causes_fail;
    return if $event->can('subevents'); # ignore subtest

    my $trace = $event->trace;
    my $file = $trace->file;
    my $line = $trace->line;
    return unless $file;
    return unless _fail_in_test_file($file);

    _make_failed_test_todo($file, $line);
}

sub _fail_in_test_file {
    my ($file) = @_;
    $file =~ /\.t\z/;
}

sub _make_failed_test_todo {
    my ($file, $line) = @_;
    my $doc = $ppi_cache->{$file} ||= PPI::Document->new($file);
    return unless $doc;
}

1;
__END__

=encoding utf-8

=head1 NAME

Test2::Plugin::MakeFailedTestTODO - It's new $module

=head1 SYNOPSIS

    use Test2::Plugin::MakeFailedTestTODO;

=head1 DESCRIPTION

Test2::Plugin::MakeFailedTestTODO is ...

=head1 LICENSE

Copyright (C) utgwkk.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

utgwkk E<lt>utagawakiki@gmail.comE<gt>

=cut

