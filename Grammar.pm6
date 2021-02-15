grammar gCNI {
	rule TOP { <stmt>* }

	proto token stmt {*}
	      token stmt:sym<section> { <.ws> <header> <comment>? }
	      token stmt:sym<rkeyval> { <.ws> <rkv>    <comment>? }
	      token stmt:sym<keyval>  { <.ws> <kv>     <comment>? }
	      token stmt:sym<comment> { <.ws>          <comment>  }

	rule header { '[' <key>? ']' }
	rule kv { <key> '=' <value> }
	rule rkv { <key> '=' <value=rvalue> }

	token comment { 
		['#' | ';'] \V* # until vertical space
	}
	token key {
		[<[a..zA..Z0..9_\-]>+]+ % '.' # alphanum + _- separated by '.'
		{ make ~$/; }
	}
	token value {
		[<-[\s#;]>+]* % \h+ # non-space non-keychar separated by horizontal whitespace
		{ make ~$/; }
	}
	token rvalue {
		'`'
		# double `` is the escape for ` inside a raw string
		(
			[<-[`]>*]* % '``' # non `s separated by double "``"s
			{ make ~$/; }
		)
		'`'
		{ make ~$/[0].subst('``', '`', :g); } # double ``s are escaped
	}
}
