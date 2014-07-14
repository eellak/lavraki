#!/usr/bin/env perl

use 5.012;
use strict;
use warnings;
use File::HomeDir;
use Time::Piece;
use Config::Std { def_sep => '=' };
use WWW::Mechanize;
use HTML::TreeBuilder;

# our configuration file
my $lavrakirc = File::HomeDir->my_home . "/.lavrakirc";
die("No $lavrakirc file found. Please create the configuration file first.")
	unless -e $lavrakirc;

# fix file permissions if not 0400
my $lavrakirc_fperms = sprintf('%04o', ((stat($lavrakirc))[2] & 0777));

if( $lavrakirc_fperms != '0400' ) {
	die("Cannot change file permissions for $lavrakirc to 0400")
		unless chmod(0400, $lavrakirc);

	say "Fixed insecure file permissions for $lavrakirc.";
}

# the configuration file for kamaki
my $kamakirc = File::HomeDir->my_home . "/.kamakirc";
die("No $kamakirc file found. I guess you have no use for this script.")
	unless -e $kamakirc;

# read our configuration file
read_config $lavrakirc => my %config;

# okeanos accounts base url
my $url = 'https://accounts.okeanos.grnet.gr/ui';

# create a new mechanize object with bogus User Agent
my $mech = WWW::Mechanize->new(agent => 'Linux Mozilla');

# get the login page to receive csrf protection token
$mech->get($url . '/login');
$mech->form_with_fields('username');
my ($csrf_input) = $mech->find_all_inputs(
	name => 'csrfmiddlewaretoken');

# bypass csrf protection
$mech->add_header('Referer', $url . '/login');
$mech->add_header('X-CSRFToken', $csrf_input->value());

# login
$mech->field(username => $config{''}{username});
$mech->field(password => $config{''}{password});
$mech->submit();

# get the API access page
$mech->get($url . '/api_access');

# build a tree from the content for easier parsing
my $content = HTML::TreeBuilder->new_from_content($mech->content);

# read the auth token
my $auth_token_input = $content->look_down(
	_tag   => q{input},
	'name' => 'auth_token',
);
my $auth_token = $auth_token_input->attr('value');

# read the expiration date
my $auth_token_exp_date = $content->look_down(
	_tag    => q{span},
	'class' => 'date',
);

# get the unformatted content of the expiration date..
my $exp_date_nofmt = $auth_token_exp_date->as_text;

# ..and convert it to a TimeDate object
my $exp_date = '';
if ($exp_date_nofmt =~ /\((.+?)\)/) {
	$exp_date = Time::Piece->strptime($1, "%b. %d, %Y");
}

# read kamakirc to compare the auth tokens
read_config $kamakirc => my %kamakiconfig;

# the cloud configuration stanza to operate on.
my $cloud = 'cloud "' . $config{''}{cloud} . '"';

# compare the tokens and upgrade
if ($auth_token ne $kamakiconfig{$cloud}{token}) {
	# the current time
	my $time = localtime;

	# backup the original kamakirc first
	write_config %kamakiconfig,
		File::HomeDir->my_home . "/.kamakirc." . $time->strftime("%s");
	
	# change the token value and write it to the original ~/.kamakirc
	$kamakiconfig{$cloud}{token} = $auth_token;
	write_config %kamakiconfig;
	
	say "The token has rotated. $kamakirc was updated.\n"
		. "The active token expires on "
		. $exp_date->strftime("%d/%m/%Y") . '.';
}
