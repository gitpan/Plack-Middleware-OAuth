package Plack::Middleware::OAuth::Handler::AccessTokenV1;
use parent qw(Plack::Middleware::OAuth::Handler);
use warnings;
use strict;
use URI;
use URI::Query;
use LWP::UserAgent;
use Net::OAuth;
use DateTime;
use Digest::MD5 qw(md5_hex);
use HTTP::Request::Common;


sub build_args {
	my $self = $_[0];
	my $config = $self->config;
	# $config contains: consumer_key consumer_secret request_token_url access_token_url request_method signature_method
	my %args = (
		$self->build_v1_common_args,
		token        => $self->param('oauth_token'),
		token_secret => '',

		request_url      => $config->{access_token_url},
		request_method   => $config->{access_token_method},
		verifier     => $self->param('oauth_verifier'),
	);
	return %args;
}

sub run {
	my $self = $_[0];
	my $provider = $self->provider;
	my $config = $self->config;
	my $env = $self->env;

    # http://app.local:3000/oauth/twitter/callback?
    #   oauth_token=
    #   oauth_verifier=
    # my $response = Net::OAuth->response( 'user auth' )->from_hash( request->params );
    my $response = Net::OAuth->response( 'user auth' )->from_hash( { 
        oauth_token    => $self->param('oauth_token'),
        oauth_verifier => $self->param('oauth_verifier'),
    });

    my $request = Net::OAuth->request( 'access token' )->new( $self->build_args );
    $request->sign;

    my $ua = LWP::UserAgent->new;
    my $ua_response = $ua->request( GET $request->to_url );

    unless($ua_response->is_success) {
        return $self->on_error->( $self, $env, $provider, $config ) if $self->on_error;
        return $self->render( $ua_response->status_line . ' ' . $ua_response->content );
    }


    $response = Net::OAuth->response( 'access token' )->from_post_body( $ua_response->content );

    my $oauth_data = +{
		version             => $config->{version},
		provider            => $provider,
		params => {
			access_token        => $response->token,
			access_token_secret => $response->token_secret,
			extra_params        => $response->extra_params
		},
    };

    my $session = Plack::Session->new( $env );
    $session->set( 'oauth.' . lc($self->provider)  . '.access_token' , $oauth_data->{params}->{access_token} );
    $session->set( 'oauth.' . lc($self->provider)  . '.access_token_secret' , $oauth_data->{params}->{access_token_secret} );

	my $res;
	$res = $self->on_success->( $self, $oauth_data ) if $self->on_success;
	return $res if $res;

	return $self->to_yaml( $oauth_data );
}

1;
