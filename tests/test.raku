#!/usr/bin/env raku
use JSON::Tiny;

use lib $*PROGRAM.dirname ~ '/..';
use Parser;

sub isfail ($name) {
	return $name.contains('fail');
}

sub TestFail($src) {
	my @fails;
	with pCNI.new.parse($src) -> $m {
		@fails.push: "meant to fail, but parsed successfully";
		for $m.made.kv -> $k, $v {
			@fails.push: "found ｢$k｣ = ｢$v｣, expected Nil";
		}
	}
	return @fails;
}

sub TestPass($src, %j) {
	my @fails;
	my $p = pCNI.new;
	with $p.parse($src) -> $m {
		for %j.keys -> $k {
			my $cv = $p<<$k>> || Nil.gist;
			my $jv = %j<<$k>>;
			@fails.push: "$k: expected ｢$jv｣ but found ｢$cv｣" if $cv ne $jv;
		}
	} else {
		@fails.push: "could not parse"
	}
	return @fails;
}

sub Test($file) {
	my $sc = $file.slurp;
	my @fails;
	if isfail $file {
		@fails = TestFail $sc;
	} else {
		my $j = from-json $file.subst('.cni', '.json').IO.slurp;
		@fails = TestPass $sc, $j;	
	}
	return @fails.map: { "$file: $_"; };
}

sub Runner($dir, :$verbose) {
	my $total = 0;
	my $pass  = 0;
	my @fails;
	
	my @todo = $dir.IO;
	while @todo {
		my $d = @todo.pop;
		for $d.dir -> $path {
			if $path.ends-with('.cni') {
				my @f = Test $path;
				$total++;
				
				if @f {
					@fails.append: @f;
					say "x> $path" if $verbose;
				} else {
					$pass++;
					say "-> $path" if $verbose;
				}
			}
			
			@todo.push: $path if $path.d;
		}
	}
	return $total, $pass, @fails;
}

sub RunRec($dir = $*PROGRAM.dirname, :$verbose) {
	say "==> $dir" if $verbose;
	my ($total, $pass, $fails) = Runner $dir, :$verbose;
	$*OUT.print: $total == $pass ?? '++' !! 'xx';
	say "> $dir: $pass/$total";
	if $fails { say "x> $_" for $fails; }
}

sub MAIN(
	*@files,
	Bool :v(:$verbose)
) {
	if ! @files {
		@files.push: $*PROGRAM.dirname ~ "/$_" for <core ini ext>;
	}
	RunRec $_, :$verbose for @files;
}
