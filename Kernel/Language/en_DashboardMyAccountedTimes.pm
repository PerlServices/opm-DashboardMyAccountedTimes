# --
# Copyright (C) 2022 - 2023 Perl-Services, https://www.perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Language::en_DashboardMyAccountedTimes;

use strict;
use warnings;

use utf8;

sub Data {
    my $Self = shift;

    my $Lang = $Self->{Translation} || {};

    $Lang->{'CurrentMonth'} = 'Current month';
    $Lang->{'CurrentWeek'} = 'Current week';
    $Lang->{'SevenDays'} = 'last 7 days';
}

1;
