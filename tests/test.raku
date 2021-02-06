#!/usr/bin/env raku
use JSON::Tiny;

use lib $*PROGRAM.dirname ~ '/..';
use Parser;

sub isfail ($name) {
	return $name.contains('fail');
}

# share fail parser between fail runs
my $failp = pCNI.new;

sub TestFail ($file) {
	my $sc = $file.slurp;

	with $failp.parse($sc) -> $m {
		say "x> $file";
		for $m.made.kv -> $k, $v {
			say "x found ｢$k｣ = ｢$v｣";
		}
	} else {
		say "-> $file";
	}
}

sub Test ($file) {
	return TestFail $file if isfail $file;

	my $sc = $file.slurp;
	my $sj = $file.subst('.cni', '.json').IO.slurp;

	my $p = pCNI.new;
	my $j = from-json $sj;

	my @fails;
	with $p.parse($sc) -> $m {
		for $j.keys -> $k {
			my $cv = $p<<$k>> || Nil.gist;
			my $jv = $j<<$k>>;
			#say $m;
			@fails.push: "x $k: expected ｢$jv｣ but found ｢$cv｣" if $cv ne $jv;
		}
	} else {
		@fails.push: "x could not parse $file";
	}

	if @fails {
		say "x> $file";
		say $_ for @fails;
		
	} else {
		say "-> $file";
	}
}

sub RunRec ($dir = $*PROGRAM.dirname) {
	my @todo = $dir.IO;
	while @todo {
		my $d = @todo.pop;
		say '==> ', $d.Str;
		for $d.dir -> $path {
			Test $path if $path.ends-with('.cni');
			@todo.push: $path if $path.d;
		}
	}
}

if ! @*ARGS {
	@*ARGS.push: $*PROGRAM.dirname ~ '/' ~ $_ for <core ini ext>
}
RunRec $_ for @*ARGS;
