package Plack::Middleware::OAuth::UserInfo::Twitter;
use warnings;
use strict;
use parent qw(Plack::Middleware::OAuth::UserInfo);
use Net::Twitter;

# interface:
#    query method

sub create_handle { 
    my $self = shift;
    my $twitter = Net::Twitter->new(
        traits              => [qw/OAuth API::REST/],
        consumer_key        => $self->config->{consumer_key},
        consumer_secret     => $self->config->{consumer_secret},
        access_token        => $self->token->access_token,
        access_token_secret => $self->token->access_token_secret,
    );
    return $twitter;
}

sub query {
    my $self = shift;
    # get twitter user infomation with (api)
    my $twitter = $self->create_handle;

#   account_settings => $twitter->account_settings,
#   account_totals => $twitter->account_totals,
    return $twitter->show_user( $self->token->extra->{screen_name} )
}

1;
