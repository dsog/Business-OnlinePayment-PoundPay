use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Business::OnlinePayment::Poundpay',
    VERSION_FROM => 'Poundpay.pm', # finds $VERSION
    AUTHOR       => 'Khaled Hussein <khaled.hussein@gmail.com>',
    PREREQ_PM    => { 
        'Business::OnlinePayment' => 0,
    }
);
