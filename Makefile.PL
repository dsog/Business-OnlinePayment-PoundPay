use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Business::OnlinePayment::PoundPay',
    VERSION_FROM => 'lib/Business/OnlinePayment/PoundPay.pm', # finds $VERSION
    AUTHOR       => 'Khaled Hussein <khaled.hussein@gmail.com>',
    PREREQ_PM    => { 
        'Business::OnlinePayment' => 0,
    }
);
