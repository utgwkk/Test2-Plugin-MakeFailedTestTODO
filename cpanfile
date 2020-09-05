requires 'perl', '5.008001';

requires 'List::Util';
requires 'PPI';
requires 'Test2::API';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test2::V0';
};

