# --
# Copyright (C) 2022 - 2023 Perl-Services.de, https://www.perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::Dashboard::MyAccountedTimes;

use strict;
use warnings;

use List::Util qw(sum0);

use Kernel::Language qw(Translatable);

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    # get needed objects
    for my $Needed (qw(Config Name UserID)) {
        die "Got no $Needed!" if ( !$Self->{$Needed} );
    }

    # check if the user has filter preferences for this widget
    my %Preferences = $Kernel::OM->Get('Kernel::System::User')->GetPreferences(
        UserID => $Self->{UserID},
    );

    $Self->{PrefKeyShown}   = 'UserDashboardPref' . $Self->{Name} . '-Shown';
    $Self->{PageShown}      = $Preferences{ $Self->{PrefKeyShown} };

    return $Self;
}

sub Preferences {
    my ( $Self, %Param ) = @_;

    my @Params = ();

    return @Params;
}

sub Config {
    my ( $Self, %Param ) = @_;

    return (
        %{ $Self->{Config} },
        CacheKey => 'MyAccountedTimes'
            . $Self->{UserID} . '-'
            . $Kernel::OM->Get('Kernel::Output::HTML::Layout')->{UserLanguage},
    );
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $DBObject     = $Kernel::OM->Get('Kernel::System::DB');
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    my %Dates = $Self->_GetDates();

    my $SQL = qq~
        SELECT time_unit, change_time
        FROM time_accounting
        WHERE change_by = ?
            AND change_time > ?
    ~;

    my $Limit = 100_000;

    return if !$DBObject->Prepare(
        SQL   => $SQL,
        Bind  => [ \$Self->{UserID}, \$Dates{CurrentMonth} ],
        Limit => $Limit,
    );

    my @AccountedTimes;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        push @AccountedTimes, [$Row[0], $Row[1]];
    }

    if ( !@AccountedTimes ) {
        $LayoutObject->Block(
            Name => 'NoTimes',
        );
    }
    else {
        my $Spans  = $ConfigObject->Get('MyAccountedTimes::Stats') || ['current_week'];
        my @ToShow = map {
            join '', map{ ucfirst $_ } split /_/, $_;
        }@{ $Spans || [] };

        for my $Span ( @ToShow ) {
            my $MinDate = $Dates{$Span};

            my @Times = grep { $_->[1] gt $MinDate } @AccountedTimes;
            my $Sum   = sum0 map{ $_->[0] } @Times;

            $LayoutObject->Block(
                Name => 'Span',
                Data => {
                    Span           => $Span,
                    AccountedTimes => $Sum,
                },
            );
        }
    }

    # render content
    my $Content = $LayoutObject->Output(
        TemplateFile => 'AgentDashboardMyAccountedTimes',
        Data         => {
            %{ $Self->{Config} },
        },
    );

    # return content
    return $Content;
}

sub _GetDates {
    my ($Self) = @_;

    my $UserObject = $Kernel::OM->Get('Kernel::System::User');

    my %Preferences = $UserObject->GetPreferences(
        UserID => $Self->{UserID},
    );

    my $DateTimeObject = $Kernel::OM->Create(
        'Kernel::System::DateTime',
        ObjectParams => {
            TimeZone => $Preferences{UserTimeZone},
        }
    );

    my $Today = $DateTimeObject->Get();

    my $CurrentMonthObject = $DateTimeObject->Clone();
    $CurrentMonthObject->Set(
        Day    => 1,
        Hour   => 0,
        Minute => 0,
        Second => 0,
    );
    $CurrentMonthObject->ToOTRSTimeZone();

    my $CurrentWeekObject = $DateTimeObject->Clone();
    $CurrentWeekObject->Subtract( Days => ( $Today->{DayOfWeek} - 1 ) );
    $CurrentWeekObject->Set(
        Hour   => 0,
        Minute => 0,
        Second => 0,
    );
    $CurrentWeekObject->ToOTRSTimeZone();

    my $SevenDaysObject = $DateTimeObject->Clone();
    $SevenDaysObject->Subtract( Days => 7 );
    $SevenDaysObject->Set(
        Hour   => 0,
        Minute => 0,
        Second => 0,
    );
    $SevenDaysObject->ToOTRSTimeZone();

    $DateTimeObject->Set(
        Hour   => 0,
        Minute => 0,
        Second => 0,
    );
    $DateTimeObject->ToOTRSTimeZone();

    my %Dates = (
        CurrentMonth => $CurrentMonthObject->ToString(),
        CurrentWeek  => $CurrentWeekObject->ToString(),
        Today        => $DateTimeObject->ToString(),
        SevenDays    => $SevenDaysObject->ToString(),
    );

    return %Dates;
}

1;
