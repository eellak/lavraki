# lavraki

[Okeanos](https://okeanos.grnet.gr/) offers API access but expires and rotates the API auth token every month, thus making process automation difficult.

Lavraki is a simple perl script that logs into your Okeanos account and updates the API auth token in ~/.kamakirc if changed.

## Requirements & Compatibility

* Perl 5.12 or newer.
* [WWW::Mechanize](https://metacpan.org/pod/WWW::Mechanize).
* [File::HomeDir](https://metacpan.org/pod/File::HomeDir).
* [Config::Std](https://metacpan.org/pod/Config::Std).
* [HTML::TreeBuilder](https://metacpan.org/pod/HTML::TreeBuilder).

The use of `cpanm` for module installation is highly recommended. In Debian you can also install the packages:

* libwww-mechanize-perl
* libfile-homedir-perl
* libconfig-std-perl

## Installation

Just copy the script somewhere in your `PATH` and make it executable. Also copy `lavrakirc.sample` as `.lavrakirc` in your `HOME`, add your configuration and change the file permissions to `0400`.

## Usage

The script returns nothing if the configured token is still valid. If the token is changed it creates a backup of `~/.kamakirc` in the form of `~/.kamakirc.TIMESTAMP`, updates the token and prints an information message.

## License

This script is licensed under the [ISC license](http://opensource.org/licenses/ISC).

## Credits

The name 'lavraki' was chosen by Vivi from ellak.gr.
