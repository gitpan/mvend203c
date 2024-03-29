# Config.pm - Configure MiniVend
# 
# $Id: Config.pm,v 2.17 1997/03/14 08:12:51 mike Exp mike $
#
# Copyright 1996,1997 by Michael J. Heins <mikeh@iac.net>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.


package Vend::Config;
require Exporter;
@ISA = qw(Exporter);
@EXPORT		= qw( config global_config );

@EXPORT_OK	= qw( get_catalog_default get_global_default parse_time parse_database);

my $C;

use strict;
use Carp;
use Fcntl;
use Vend::Util;

for( qw(search refresh cancel return secure
		set unsecure submit control checkout) ) {
	$Global::LegalAction{$_} = 1;
}

my %SetGlobals;

sub global_directives {

	my $directives = [
#   Order is not really important, catalogs are best first

#   Directive name      Parsing function    Default value

    ['PageCheck',		 'yesno',     	     'no'],
    ['DisplayErrors',    'yesno',            'Yes'],
    ['TcpPort',           undef,             '7786'],
    ['TcpHost',           undef,             'localhost'],
	['SendMailProgram',  'executable',       $Global::SendMailLocation],
    ['ForkSearches',	 'yesno',     	     'no'],
	['HouseKeeping',      undef,             60],
	['MaxServers',        undef,             2],
	['GlobalSub',		 'subroutine',       ''],
    ['LogFile', 		  undef,     	     'etc/log'],
    ['SafeUntrap',		 'array',     	     do { my $r = '249 148';
												  eval {require 5.00320};
												  unless($@) {
													  $r = 'ftfile sort'
												  }
												  $r } ],
	['MailErrorTo',		  undef,			 'webmaster'],
    ['HammerLock',		  undef,     	     30],
    ['DebugMode',		  undef,     	     0],
    ['MultiServer',		 'yesno',     	     0],
    ['Catalog',			 'catalog',     	 ''],

    ];
	return $directives;
}


sub catalog_directives {

	my $directives = [
#   Order is somewhat important, the first 6 especially

#   Directive name      Parsing function    Default value

	['ErrorFile',        undef,              'error.log'],
	['PageDir',          'relative_dir',     'pages'],
	['ProductDir',       'relative_dir',     'products'],
	['OfflineDir',       'relative_dir',     'offline'],
	['DataDir',          'relative_dir',     'products'],
	['Delimiter',        'delimiter',        'TAB'],
    ['SpecialPage',		 'special',     	 ''],
    ['ActionMap',		 'action',	     	 ''],
	['VendURL',          'url',              undef],
	['SecureURL',        'url',              undef],
	['OrderReport',      'valid_page',       'etc/report'],
	['ScratchDir',       'relative_dir',     'etc'],
	['SessionDatabase',  'relative_dir',     'session'],
	['SessionLockFile',  undef,     		 'etc/session.lock'],
	['Database',  		 'database',     	 ''],
	['Sub',			  	 'variable',     	 ''],
	['Variable',	  	 'variable',     	 ''],
	['WritePermission',  'permission',       'user'],
	['ReadPermission',   'permission',       'user'],
	['SessionExpire',    'time',             '1 day'],
	['MailOrderTo',      undef,              undef],
	['SendMailProgram',  'executable',       $Global::SendMailLocation],
	['PGP',              undef,       		 ''],
    ['Glimpse',          'executable',       ''],
    ['Locale',           'locale',           ''],
    ['RequiredFields',   undef,              ''],
    ['MsqlProducts',   	 'yesno',            'No'],
    ['MsqlDB',   		 undef,              'minivend'],
    ['ReceiptPage',      'valid_page',       ''],
    ['ReportIgnore',     undef, 			 'credit_card_no,credit_card_exp'],
    ['OrderCounter',	 undef,     	     ''],
    ['ImageDir',	 	 undef,     	     ''],
    ['UseCode',		 	 undef,     	     'yes'],
    ['UseModifier',		 'array',     	     ''],
    ['LogFile', 		  undef,     	     'etc/log'],
    ['CollectData', 	 'boolean',     	 ''],
    ['PriceBreaks',	 	 'array',  	     	 ''],
    ['PriceDivide',	 	 undef,  	     	 1],
    ['MixMatch',		 'yesno',     	     'No'],
    ['AlwaysSecure',	 'boolean',  	     ''],
	['Password',         undef,              ''],
    ['ExtraSecure',		 'yesno',     	     'No'],
    ['Cookies',			 'yesno',     	     'No'],
    ['MasterHost',		 undef,     	     ''],
    ['RemoteUser',		 undef,     	     ''],
    ['TaxShipping',		 undef,     	     ''],
	['FractionalItems',  'yesno',			 'No'],
	['SeparateItems',    'yesno',			 'No'],
    ['PageSelectField',  undef,     	     ''],
    ['NonTaxableField',  undef,     	     ''],
    ['CreditCardAuto',	 'yesno',     	     'No'],
    ['CreditCards',		 'yesno',     	     'No'],
    ['SearchCache',	     'cache',     	     ''],
    ['EncryptProgram',	 undef,     	     ''],
    ['AsciiTrack',	 	 undef,     	     ''],
    ['AsciiBackend',	 undef,     	     ''],
    ['Tracking',		 undef,     	     ''],
    ['BackendOrder',	 undef,     	     ''],
    ['SalesTax',		 undef,     	     ''],
    ['StaticPath',		 undef,     	     ''],
    ['CustomShipping',	 undef,     	     ''],
    ['DefaultShipping',	 undef,     	     'default'],
    ['UpsZoneFile',		 undef,     	     ''],
    ['OrderProfile',	 'profile',     	 ''],
    ['SearchProfile',	 'profile',     	 ''],
    ['PriceCommas',		 undef,     	     'yes'],
    ['ItemLinkDir',	 	 undef,     	     ''],
    ['SearchOverMsg',	 undef,           	 ''],
	['SecureOrderMsg',   undef,              'Use Order Security'],
    ['SearchFrame',	 	 undef,     	     '_self'],
    ['OrderFrame',	     undef,              '_top'],
    ['CheckoutFrame',	 undef,              '_top'],
    ['CheckoutPage',	 'valid_page',       'order'],
    ['FrameOrderPage',	 'valid_page',       ''],
    ['FrameSearchPage',	 'valid_page',       ''],
    ['DescriptionTrim',  undef,              ''],
    ['DescriptionField', undef,              'description'],
    ['PriceField',		 undef,              'price'],
    ['ItemLinkValue',    undef,              'More Details'],
	['FinishOrder',      undef,              'Finish Incomplete Order'],
	['Shipping',         undef,               0],
	['Help',            'help',              ''],
	['Random',          'random',            ''],
	['Rotate',          'random',            ''],
	['ButtonBars',      'buttonbar',         ''],
	['Mv_Background',   'color',             ''],
	['Mv_BgColor',      'color',             ''],
	['Mv_TextColor',    'color',             ''],
	['Mv_LinkColor',    'color',             ''],
	['Mv_AlinkColor',   'color',             ''],
	['Mv_VlinkColor',   'color',             ''],

    ];
	return $directives;
}

sub get_catalog_default {
	my ($directive) = @_;
	my $directives = catalog_directives();
	my $value;
	for(@$directives) {
		next unless (lc $directive) eq (lc $_->[0]);
		$value = $_->[2];
	}
	return undef unless defined $value;
	return $value;
}

sub get_global_default {
	my ($directive) = @_;
	my $directives = global_directives();
	my $value;
	for(@$directives) {
		next unless (lc $directive) eq (lc $_->[0]);
		$value = $_->[2];
	}
	return undef unless defined $value;
	return $value;
}
## CONFIG

# Report an error MSG in the configuration file.

sub config_error {
    my($msg) = @_;
	my $name = defined $C ? $C->{ConfigFile} : 'minivend.cfg';

    die "$msg\nIn line $. of the configuration file '$name':\n" .
	"$Vend::config_line\n";
}

# Report a warning MSG about the configuration file.

sub config_warn {
    my($msg) = @_;
	my $name = defined $C ? $C->{ConfigFile} : 'minivend.cfg';

    logGlobal("$msg\nIn line $. of the configuration file '" .
	     $name . "':\n" . $Vend::config_line . "\n");
}

# Each of the parse functions accepts the value of a directive from the
# configuration file as a string and either returns the parsed value or
# signals a syntax error.

# Sets a boolean array for any type of item, currently only
# AlwaysSecure and CollectData
sub parse_boolean {
	my($item,$settings) = @_;
	my(@setting) = split /[\s,]+/, $settings;
	my $c;
	unless (@setting) {
		$c = {};
		return $c;
	}

	if($item =~ /CollectData/i) {
		$c = $C->{'CollectData'};
	}
	else {
		$c = $C->{'AlwaysSecure'};
	}

	for (@setting) {
		$c->{$_} = 1;
	}
	return $c;
}


# Adds an action to the Action Map
# Deletes if the action is delete
sub parse_action {
	my($item,$setting) = @_;

	unless ($setting) {
		# Set the initial action map
		my $c = {};
		%$c = (
		'account'		=>  'secure',
		'browse'		=>  'return',
		'cancel'		=>  'cancel',
		'check out'		=>  'checkout',
		'checkout'		=>  'checkout',
		'control'		=>  'control',
		'find'			=>  'search',
		'log out'		=>  'cancel',
		'order'			=>  'submit',
		'place'			=>  'submit',
		'place order'	=>  'submit',
		'recalculate'	=>  'refresh',
		'refresh'		=>  'refresh',
		'return'		=>  'return',
		'scan'			=>  'scan',
		'search'		=>  'search',
		'secure'		=>  'secure',
		'submit order'	=>  'submit',
		'submit'		=>  'submit',
		'unsecure'		=>  'unsecure',
		'update'		=>  'refresh',
		);
		return $c;
	}

	my($action,$string) = split /\s+/, $setting, 2;
	$action = lc $action;
	return delete $C->{'ActionMap'}->{$string} if $action eq 'delete';
	$C->{'ActionMap'}->{$string} = $action;
	config_error("Unrecognized action '$action'")
		unless $Global::LegalAction{$action};
	return $C->{'ActionMap'};
}

use POSIX;

# Sets the special locale array. Tries to use POSIX setlocale,
# accepts a 'custom' setting with the proper definitions of
# decimal_point,  mon_thousands_sep, and frac_digits (the only supported at
# the moment).  Otherwise uses US-English settings if not set.
sub parse_locale {
    my($item,$settings) = @_;
	return '' unless $settings;
	$settings = '' if "\L$settings" eq 'default';
    my $name;
    my $c = {};

    # Try POSIX first.
    $name = POSIX::setlocale(POSIX::LC_ALL, $settings);

    if (defined $name and $name) {
        $c = POSIX::localeconv();
        $c->{mon_thousands_sep} = ','
            unless $c->{mon_thousands_sep};
        $c->{decimal_point} = '.'
            unless $c->{decimal_point};
        $c->{frac_digits} = 2
            unless defined $c->{frac_digits};
        $c->{Name} = $name;
    }
    # else Try to read the ones we have defined
    elsif($settings eq 'pt') {
        $c->{decimal_point} = ',';
        $c->{mon_thousands_sep} = '.';
        $c->{frac_digits} = 2;
        $c->{Name} = 'Portugal';
    }
    elsif ($settings =~ /^custom\s+/) {

        my(@setting) = split /\s+/, $settings;
        $c->{Name} = shift(@setting);
        my(%setting) = @setting;
        for (keys %setting) {
            $c->{$_} = $setting{$_};
        }
        $c->{mon_thousands_sep} = ','
            unless $c->{mon_thousands_sep};
        $c->{decimal_point} = '.'
            unless $c->{decimal_point};
        $c->{frac_digits} = 2
            unless defined $c->{frac_digits};
    }
    else {
        config_error("Bad Locale setting $settings.\n");
    }

    return $c;
}


# Sets the special page array
sub parse_special {
	my($item,$settings) = @_;
	unless ($settings) {
		my $c = {};
	# Set the special page array
		%$c = (
		qw(
			badsearch		badsearch
			canceled		canceled
			catalog			catalog
			checkout		checkout
			confirmation	confirmation
			control			control
			failed			failed
			flypage			flypage
			interact		interact
			missing			missing	
			needfield		needfield
			nomatch			nomatch
			noproduct		noproduct
			notfound		notfound
			order			order
			search			search
			violation		violation
			)
		);
		return $c;
	}
	my(%setting) = split /\s+/, $settings;
	for (keys %setting) {
		$C->{'SpecialPage'}->{$_} = $setting{$_};
	}
	return $C->{'SpecialPage'};
}

sub parse_array {
	my($item,$settings) = @_;
	my(@setting) = split /[\s,]+/, $settings;

	return 0 unless (@setting);

	my $c = [];
	for (@setting) {
		push @{$c}, $_;
	}
	$c;
}

# Check that an absolute pathname starts with /, and remove a final /
# if present.

sub parse_absolute_dir {
    my($var, $value) = @_;

    config_warn("The $var directive (now set to '$value') should probably\n" .
	  "start with a leading /.")
	if $value !~ m.^/.;
    $value =~ s./$..;
    $value;
}

# Prepend the VendRoot pathname to the relative directory specified,
# unless it already starts with a leading /.

sub parse_relative_dir {
    my($var, $value) = @_;

    config_error(
      "Please specify the VendRoot directive before the $var directive\n")
	unless defined $C->{'VendRoot'};
    $value = "$C->{'VendRoot'}/$value" unless $value =~ m.^/.;
    $value =~ s./$..;
    $value;
}


sub parse_url {
    my($var, $value) = @_;

    config_warn(
      "The $var directive (now set to '$value') should probably\n" .
      "start with 'http:' or 'https:'")
	unless $value =~ m/^https?:/i;
    $value =~ s./$..;
    $value;
}

# Parses a time specification such as "1 day" and returns the
# number of seconds in the interval, or undef if the string could
# not be parsed.

sub time_to_seconds {
    my($str) = @_;
    my($n, $dur);

    ($n, $dur) = ($str =~ m/(\d+)\s*(\w+)?/);
    return undef unless defined $n;
    if (defined $dur) {
	$_ = $dur;
	if (m/^s|sec|secs|second|seconds$/i) {
	} elsif (m/^m|min|mins|minute|minutes$/i) {
	    $n *= 60;
	} elsif (m/^h|hour|hours$/i) {
	    $n *= 60 * 60;
	} elsif (m/^d|day|days$/i) {
	    $n *= 24 * 60 * 60;
	} elsif (m/^w|week|weeks$/i) {
	    $n *= 7 * 24 * 60 * 60;
	} else {
	    return undef;
	}
    }

    $n;
}

sub parse_valid_page {
    my($var, $value) = @_;
    my($page,$x);

	return $value if !$C->{'PageCheck'};

	if( ! defined $value or $value eq '') {
		return $value;
	}

    config_error("Can't find valid page ('$value') for the $var directive\n")
		unless -s "$C->{'PageDir'}/$value.html";
    $value;
}


sub parse_executable {
    my($var, $value) = @_;
    my($x);
	my $root = $value;
	$root =~ s/\s.*//;

	if( ! defined $value or $value eq '') {
		$x = '';
	}
	elsif ($root =~ m#^/# and -x $root) {
		$x = $value;
	}
	else {
		my @path = split /:/, $ENV{PATH};
		for (@path) {
			next unless -x "$_/$root";
			$x = $value;
		}
	}

    config_error("Can't find executable ('$value') for the $var directive\n")
		unless defined $x;
    $x;
}

sub parse_time {
    my($var, $value) = @_;
    my($n);

    $n = time_to_seconds($value);
    config_error("Bad time format ('$value') in the $var directive\n")
	unless defined $n;
    $n;
}

sub parse_catalog {
	my ($var, $value) = @_;
	my $num = ! defined $Global::Catalog ? 0 : $Global::Catalog;
	return $num unless (defined $value && $value); 

	my($name,$dir,$script) = split /[\s,]+/, $value, 3;

	${Global::Catalog{$name}}->{'name'} = $name;
	${Global::Catalog{$name}}->{'dir'} = $dir;
	${Global::Catalog{$name}}->{'script'} = $script;
	return ++$num;
}

sub parse_database {
	my ($var, $value) = @_;
	my $c;
	unless (defined $value && $value) { 
		$c = {};
		return $c;
	}
	$c = $C->{'Database'};
	
	my($database,$file,$type) = split /[\s,]+/, $value, 3;

	$c->{$database}->{'file'} = $file;
	$c->{$database}->{'type'} = $type;

	return $c;
}

sub parse_profile {
	my ($var, $value) = @_;
	my ($c, $n, $i);
	unless (defined $value && $value) { 
		$c = [];
		$C->{"${var}Name"} = {};
		return $c;
	}

	$c = $C->{$var};

	$n = $C->{"${var}Name"};

	my (@files) = split /[\s,]+/, $value;
	for(@files) {
		push @$c, (split /\s*[\r\n]+__END__[\r\n]+\s*/, readfile($_));
	}
	for($i = 0; $i < @$c; $i++) {
		if($c->[$i] =~ s/(^|\n)__NAME__\s+(.+)\n//) {
			my $name = $2;
			$n->{$name} = $i;
		}
	}

	return $c;
}

# Designed to parse catalog subroutines and vars
sub parse_variable {
	my ($var, $value) = @_;
	my ($c, $name, $param);
	unless (defined $value and $value) { 
		$c = {};
		return $c;
	}

	$c = $C->{$var};

	if($value =~ s/^\s*sub\s+(\w+)\s*{\s*//) {
		$name = $1;
		($param = $value) =~ s/}\s*$//;
	}
	elsif($value =~ /\n/) {
		($name, $param) = split /\r?\n/, $value, 2;
		$name =~ s/^\s+//;
		$name =~ s/\s+$//;
		chomp $param;
	}
	else {
		($name, $param) = split /\s+/, $value, 2;
	}
	$c->{$name} = $param;
	return $c;
}


# Designed to parse Global subroutines only
sub parse_subroutine {
	my ($var, $value) = @_;
	my ($c, $name);
	unless (defined $value and $value) { 
		$c = {};
		return $c;
	}

	no strict 'refs';
	$c = ${"Global::$var"};

	$value =~ s/\s*sub\s+(\w+)\s*{/sub {/;
	config_error("Bad $var: no subroutine name? ") unless $name = $1;

	$c->{$name} = eval $value;
	config_error("Bad $var '$name'") if $@;
	return $c;
}

sub parse_buttonbar {
	my ($var, $value) = @_;
	my ($c);
	unless (defined $value and $value) { 
		$c = [];
		return $c;
	}
	$c = $C->{'ButtonBars'};
	@{$c}[0..15] = get_files($C->{'PageDir'}, split /\s+/, $value);
	return $c;
}

sub parse_delimiter {
	my ($var, $value) = @_;

	return "\t" unless (defined $value && $value); 
	
	$value =~ /^CSV$/i and return 'CSV';
	$value =~ /^tab$/i and return "\t";
	$value =~ /^pipe$/i and return "\|";
	$value =~ s/^\\// and return $value;
	$value =~ s/^'(.*)'$/$1/ and return $value;
	return quotemeta $value;
}

sub parse_help {
	my ($var, $value) = @_;
	my (@files);
	my (@items);
	my ($c, $chunk, $item, $help, $key);
	unless (defined $value && $value) { 
		$c = {};
		return $c;
	}
	$c = $C->{'Help'};
	$var = lc $var;
	@files = get_files($C->{'PageDir'}, split /\s+/, $value);
	foreach $chunk (@files) {
		@items = split /\n\n/, $chunk;
		foreach $item (@items) {
			($key,$help) = split /\s*\n/, $item, 2;
			if(defined $c->{$key}) {
				$c->{$key} .= $help;
			}
			else {
				$c->{$key} = $help;
			}
				
		}
	}
	return $c;
}
		

sub parse_random {
	my ($var, $value) = @_;
	return '' unless (defined $value && $value); 
	my $c = [];
	$var = lc $var;
	@{$c} = get_files($C->{'PageDir'}, split /\s+/, $value);
	return $c;
}
		
sub parse_color {
    my ($var, $value) = @_;
	return '' unless (defined $value && $value);
    $var = lc $var;
	$C->{Color}->{$var} = [];
    @{$C->{'Color'}->{$var}}[0..15] = split /\s+/, $value, 16;
    return $value;
}
    

# Returns 1 for Yes and 0 for No.

sub parse_yesno {
    my($var, $value) = @_;

    $_ = $value;
    if (m/^y/i || m/^t/i || m/^1/) {
	return 1;
    } elsif (m/^n/i || m/^f/i || m/^0/) {
	return 0;
    } else {
	config_error("Use 'yes' or 'no' for the $var directive\n");
    }
}

sub parse_permission {
    my($var, $value) = @_;

    $_ = $value;
    tr/A-Z/a-z/;
    if ($_ ne 'user' and $_ ne 'group' and $_ ne 'world') {
	config_error(
"Permission must be one of 'user', 'group', or 'world' for
the $var directive\n");
    }
    $_;
}


# Parse the configuration file for directives.  Each directive sets
# the corresponding variable in the Config:: package.  E.g.
# "DisplayErrors No" in the config file sets Config::DisplayErrors to 0.
# Directives which have no default value ("undef") must be specified
# in the config file.

sub config {
	my($catalog, $dir, $confdir) = @_;
    my($directives, $d, %name, %parse, $var, $value, $lvar, $parse);
    my($directive);

	$C = {};
	$C->{'CatalogName'} = $catalog;
	$C->{'VendRoot'} = $dir;
	$C->{'ConfDir'} = $confdir;
	$C->{'ErrorFile'} = $Global::ErrorFile;
	$C->{'ConfigFile'} = defined $Global::Standalone
						 ? 'minivend.cfg' : 'catalog.cfg';
    no strict 'refs';

    $directives = catalog_directives();

    foreach $d (@$directives) {
		($directive = $d->[0]) =~ tr/A-Z/a-z/;
		$name{$directive} = $d->[0];
		if (defined $d->[1]) {
			$parse = 'parse_' . $d->[1];
		} else {
			$parse = undef;
		}
		$parse{$directive} = $parse;
		$value = $d->[2];
		if (defined $parse and defined $value) {
			$value = &$parse($d->[0], $value);
		}
		$C->{$name{$directive}} = $value;
    }

    open(Vend::CONFIG, $C->{ConfigFile})
	|| die "Could not open configuration file '" . $C->{ConfigFile} .
                "' for catalog '" . $catalog . "':\n$!\n";
    while(<Vend::CONFIG>) {
		chomp;			# zap trailing newline,
		s/^\s*#.*//;    # comments,
		s/\s+$//;		#  trailing spaces
		next if $_ eq '';
		$Vend::config_line = $_;
		# lines read from the config file become untainted
		m/^(\w+)\s+(.*)/ or config_error("Syntax error");
		$var = $1;
		$value = $2;
		($lvar = $var) =~ tr/A-Z/a-z/;

		if ($value =~ /^<<(.*)/) {                  # "here" value
			my $eotmark  = $1;
			my $foundeot = 0;
			my $startline = $.;
			$value = '';
			while (<Vend::CONFIG>) {
				if ($_ =~ m{^$eotmark$}) {
				  $foundeot = 1;
				  last;
				}
			    $value .= $_;
			}
			unless ($foundeot) {
				config_error (sprintf('%d: %s', $startline,
					qq#no end marker ("$eotmark") found#));
			}
		}

		# Don't error out on Global directives if we are standalone, just skip
		next if defined $Global::Standalone && defined $SetGlobals{$lvar};

		# Now we can give an unknown error
		config_error("Unknown directive '$var'") unless defined $name{$lvar};

		$parse = $parse{$lvar};
					# call the parsing function for this directive
		$value = &$parse($name{$lvar}, $value) if defined $parse;
					# and set the $C->directive variable
		$C->{$name{$lvar}} = $value;
    }
    close Vend::CONFIG;

    # check for unspecified directives that don't have default values
    foreach $var (keys %name) {
        if (!defined $C->{$name{$var}}) {
            die "Please specify the $name{$var} directive in the\n" .
            "configuration file '$C->{'ConfigFile'}'\n";
        }
    }
	$C->{'Special'} = $C->{'SpecialPage'};
	return $C;
}

# Parse the global configuration file for directives.  Each directive sets
# the corresponding variable in the Global:: package.  E.g.
# "DisplayErrors No" in the config file sets Global::DisplayErrors to 0.
# Directives which have no default value ("undef") must be specified
# in the config file.

sub global_config {
    my($directives, $d, %name, %parse, $var, $value, $lvar, $parse);
    my($directive, $seen_catalog);
    no strict 'refs';

    $directives = global_directives();

	# Prevent parsers from thinking it is a catalog
	undef $C;

    foreach $d (@$directives) {
	($directive = $d->[0]) =~ tr/A-Z/a-z/;
	$name{$directive} = $d->[0];
	if (defined $d->[1]) {
	    $parse = 'parse_' . $d->[1];
	} else {
	    $parse = undef;
	}
	$parse{$directive} = $parse;
	$value = $d->[2];
	if (defined $parse and defined $value) {
	    $value = &$parse($d->[0], $value);
	}
	${'Global::' . $name{$directive}} = $value;
    }

    open(Vend::GLOBAL, $Global::ConfigFile)
	|| die "Could not open configuration file '" .
                $Global::ConfigFile . "':\n$!\n";
    while(<Vend::GLOBAL>) {
	chomp;			# zap trailing newline,
	s/^\s*#.*//;            # comments,
				# mh 2/10/96 changed comment behavior
				# to avoid zapping RGB values
				#
	s/\s+$//;		#  trailing spaces
	next if $_ eq '';
	$Vend::config_line = $_;
	# lines read from the config file become untainted
	m/^(\w+)\s+(.*)/ or config_error("Syntax error");
	$var = $1;
	$value = $2;
	($lvar = $var) =~ tr/A-Z/a-z/;

	if ($value =~ /^<<(.*)/) {                  # "here" value
		my $eotmark  = $1;
		my $foundeot = 0;
		my $startline = $.;
		$value = '';
		while (<Vend::GLOBAL>) {
			if ($_ =~ m{^$eotmark$}) {
			  $foundeot = 1;
			  last;
			}
			$value .= $_;
		}
		unless ($foundeot) {
			config_error (sprintf('%d: %s', $startline,
				qq#no end marker ("$eotmark") found#));
		}
	}

	# Error out on extra parameters only if we know
	# we are not standalone
	unless (defined $name{$lvar}) {
		next unless $seen_catalog;
		config_error("Unknown directive '$var'")
	}
	else {
		$seen_catalog = 1 if $lvar eq 'catalog';
		$SetGlobals{$lvar} = 1;
	}

	$parse = $parse{$lvar};
				# call the parsing function for this directive
	$value = &$parse($name{$lvar}, $value) if defined $parse;
				# and set the Global::directive variable
	${'Global::' . $name{$lvar}} = $value;
    }
    close Vend::GLOBAL;

    # check for unspecified directives that don't have default values
    foreach $var (keys %name) {
        if (!defined ${'Global::' . $name{$var}}) {
            die "Please specify the $name{$var} directive in the\n" .
            "configuration file '$Global::ConfigFile'\n";
        }
    }

	unless($Global::Catalog) {
		print "Configuring standalone catalog...";
		$Global::Standalone = 0;
		$Global::Standalone =
			 config('standalone', $Global::VendRoot, $Global::ConfDir);
		print "done.\n";
	}
}

sub parse_cache {

	my ($var,$file) = @_;
	return '' unless defined $file && $file;
	my ($ref,$sub);

	my %tie;

	no strict 'refs';
	if($Global::GDBM) {
		require GDBM_File;
		import GDBM_File;
        unlink $file . '.gdbm';
        $sub = sub { my %tie;
					 if(defined $_[1]) {
						tie(%tie, 'GDBM_File', $file . '.gdbm',
								&GDBM_WRCREAT | &GDBM_FAST, 0600)
							or return undef;
					 	$tie{$_[0]} = $_[1];
						untie %tie;
					 }
					 tie(%tie, 'GDBM_File', $file . '.gdbm', &GDBM_READER, 0600)
							or return undef;
					 my $key = $tie{$_[0]};
					 untie %tie or return undef;
					 $key;
					 };
    }
    elsif($Global::DB_File) {
		require DB_File;
		import DB_File;
        unlink $file . '.db';
        $sub = sub { my %tie;
					 if(defined $_[1]) {
						 tie(%tie, 'DB_File', $file . '.db', &O_RDWR|&O_CREAT, 0600)
							or return undef;
					 	$tie{$_[0]} = $_[1];
						untie %tie;
					 }
					 tie(%tie, 'DB_File', $file . '.db', &O_RDONLY, 0600)
							or return undef;
					 my $key = $tie{$_[0]};
					 untie %tie or return undef;
					 $key;
					 };
    }
	else { return '' }  # If no large DBM, return with nada

	$ref = &$sub("1", "1") || config_error "Unable to tie search cache.\n";
	untie $ref;

	$sub;
}

1;
