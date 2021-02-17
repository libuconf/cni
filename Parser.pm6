use Grammar;

class pCNI is Hash {
	has Str $.prefix = '';

	# utility to get proper prefixes
	method prefixify($key) {
		if $!prefix { return $!prefix ~ '.' ~ $key; }
		return $key;
	}

	# parsing methods
	method TOP($/) {
		my %out;
		for $<stmt> { %out = %out, $_.made || (%); }
		make %out;
	}

	method stmt:sym<keyval> ($/) {
		make $<kv>.made;
	}
	method stmt:sym<rkeyval> ($/) {
		make $<rkv>.made;
	}

	method header($/) { $!prefix = $<key>.made; }
	method kv($/)  { make self.prefixify($<key>.made) => $<value>.made; }
	method rkv($/) { make self.prefixify($<key>.made) => $<value>.made; }

	# parsing passthrough-ish
	method parse($target) {
		my $match = gCNI.parse($target, actions => self);
		fail "Parse failed" if ! $match.defined;
		self = self, $match.made;
		return $match;
	}

	# recommended API methods
	# recommended ones for export start with a capital

	# walk over keys matching a matcher
	# this is an internal routine for providing the other stuff
	method walk($m, &c) {
		for self.keys -> $k {
			&c($k) if $k ~~ $m;
		}
	}

	# private common code between SubRec and SubFlat
	method sub($prefix, $cc) {
		my $mr = /^/;
		given $prefix {
			when '' { succeed; }
			default { $mr = /^ $prefix '.' /; }
		}
		my $m  = / <$mr> (<$cc>+) $/;

		my %out;
		self.walk: $m, {
			my $k = $^a.subst: $mr;
			%out<<$k>> = self<<$^a>>;
		}
		return %out;
	}

	
	# returns kv pairs of all keys in a section, with the section stripped
	method SubTree($prefix) {
		return self.sub: $prefix, /./;
	}

	# returns kv pairs of all keys directly in a section, with the section stripped
	method SubLeaves($prefix) {
		return self.sub: $prefix, /<-[.]>/;
	}

	# returns a list of all values in a section
	method ListTree($prefix) {
		return self.SubTree($prefix).values.list;
	}

	# returns a list of all values directly in the section
	method ListLeaves($prefix) {
		return self.SubLeaves($prefix).values.list;
	}

	# you are also recommended to implement WalkFlat and WalkRec alongside the above
}
