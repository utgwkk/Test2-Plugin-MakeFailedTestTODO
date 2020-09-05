package Test2::Plugin::MakeFailedTestTODO;
use 5.008001;
use strict;
use warnings;

use List::Util qw(any);
use PPI;
use Test2::API qw(
    test2_add_callback_post_load
    test2_stack
);

our $VERSION = "0.01";

my $loaded;

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
    my $doc = PPI::Document->new($file);
    return unless $doc;

    my $test_stmt = $doc->find_first(sub {
        my (undef, $elem) = @_;
        $elem->isa('PPI::Statement')
        && any { $_->line_number == $line } $elem->children;
    });
    return unless $test_stmt;

    # todo 'made TODO by Test2::Plugin::MakeFailedTestTODO' => sub { ... };
    warn $line;
    my $todo_stmt = do {
        my $stmt = PPI::Statement->new;
        for my $child (
            PPI::Token::Word->new('todo'),
            PPI::Token::Whitespace->new(' '),
            PPI::Token::Quote::Single->new("'made TODO by Test2::Plugin::MakeFailedTestTODO'"),
            PPI::Token::Whitespace->new(' '),
            PPI::Token->new('=>'),
            PPI::Token::Whitespace->new(' '),
            PPI::Token::Word->new('sub'),
            PPI::Token::Whitespace->new(' '),
        ) {
            $stmt->add_element($child);
        }
        my $sub = do {
            my $_sub = PPI::Structure::Block->new(
                PPI::Token::Structure->new('{'),
            );
            $_sub->{finish} = PPI::Token::Structure->new('}'),
            $_sub->add_element(PPI::Token::Whitespace->new(' '));
            $_sub->add_element($test_stmt->clone);
            $_sub->add_element(PPI::Token::Whitespace->new(' '));
            $_sub;
        };
        $stmt->add_element($sub);
        $stmt->add_element(PPI::Token::Structure->new(';'));
        $stmt;
    };

    $test_stmt->insert_before($todo_stmt);
    $test_stmt->remove;

    $doc->save($file);
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

