# CNI Specification
Note that the prime source of information about CNI is to be considered the reference implementation and test suite.
This document is a reading companion (rather than the source of truth) that should help expediate the development of implementations.

## Core Language
A CNI document consists of an arbitrary amount of statements.
A statement may either be a section declaration, key-value pair, or key-rawvalue pair.

### Key
A key is composed of alphanumeric (`[a-zA-Z0-9]`) characters, underscores, and dashes.
Keys may contain dots, but may not start or end with them.
Two dots in a row are disallowed (due to being nonsensical), but implementations do not need to explicitly disallow them.

### Section Declaration
A section consists of an opening bracket (`[`), the section name, and a closing bracket (`]`).
The section name may either be a valid key, or empty.

Until the next section, all keys will be automatically prepended the section name and a `.`, or with nothing (if the section name is the empty string).

### Key-(Raw)Value Pairs
A key-value and key-rawvalue pair look very similar.
It's a key, an equals, and a value, with arbitrary amounts of spaces before and after the `=`.

A value may contain any UTF-8 characters except vertical whitespace or the `#` sign (note: this is expanded upon in ini-compatibility).
It may not start or end with whitespace, or start with a backtick.

A rawvalue starts with a backtick and ends with a backtick, but may contain any UTF-8 characters besides those.
If a backtick needs to be inserted into a raw value, a backtick may be escaped with a second one.

Theoretically, this means that both values and raw values may contain arbitrary bytes, but the specification is exclusively intended to be used with UTF-8 data.
Implementations are not required to validate it, though.

### Comments
A comment starts with a `#` (note: this is expanded upon in ini-compatibility) and ends at the next newline.
A comment may start on its own line, at any point inside of a value, after a section declaration, or after a raw value.
It is impossible to have comments inside of a raw value, or inside of a section declaration.

## Ini-Compatibility
For compatibility with INI, the `;` character may also be used for comments.
In this case, anytime the `#` is a significant character in the core language, the `;` character should be as well.

## Extensions
All extensions are fully optional.
Currently, multiple of them are consequences of keeping the grammar lean, and are documented, but only parts of their behaviors are desirable.

### Flexspace
In implementations with the "flexspace" extension, whitespace within statements is not significant.
This means that you may have arbitrary whitespace (not only spaces, but also tabs, newlines, zero-width spaces, and so on) in the following locations:
* Between the opening section bracket, the section name, and the closing section bracket.
* Between the key in a key-(raw)value pair, the `=`, and the (raw)value.
* Between a (raw) value and a comment.

### Tabulation
In implementations with the "tabulation" extension, whitespace before and after statements is not significant.
This means you may have arbitrary whitespace in the following locations:
* In front of a section declaration.
* In front of a key-(raw)value pair.
* In front of a comment.
* Between a key-rawvalue pair and the next statement.
* Between a section declaration and the next statement.

## API
This API is purely a suggestion for the sake of users - implementations may follow any scheme they wish.

Backend storage should be implemented in a trie-like fashion, separated by `.`s.
It should be possible to get the direct list of children of a trie node, as well as the full list of children of a trie node.
It should be possible to know if a given key is a section, key, both, or neither.
It should be possible to walk over matches without requiring allocation of a new trie.
Keys do not need to be ordered in any specific way, but sorting them may make implementing the API easier.

The following API endpoints provide all of this functionality:

### Walk (Flat|Rec)
WalkFlat|WalkRec takes a pattern (which may be empty) and a function.
It will call the function with each matching key-value pair.
The matches are performed like so:
1. If the pattern is empty, all keys match.
2. If the pattern is an invalid key, no keys match.
3. If the pattern is a valid key:
   With the Rec variant, all keys that start with the pattern followed by a "." match.
   With the Flat variant, all keys that start with the pattern followed by a ".", but that do not contain any additional "."s beyond those match.

### List (Flat|Rec)
ListFlat|ListRec takes a pattern and returns a list of values.
The list will contain all of the values (including duplicates) that match under the corresponding `Walk*` function.
It can be implemented in pseudocode using the `Walk*` functions like so:

```
ListFlat (pattern):
	var output_list
	WalkFlat (pattern, (key, value){
		output_list.append(value)
	})
	return output_list
ListRec (pattern):
	var output_list
	WalkRec (pattern, (key, value){
		output_list.append(value)
	})
	return output_list
```

### Sub (Flat|Rec)
SubFlat|SubRec takes a pattern, and constructs a new trie.
The new trie will contain all of the key-value pairs that match under the corresponding `Walk*` function, but with the pattern (and the dot immediately after it) stripped.
It can be implemented in pseudocode using the `Walk*` functions like so:

```
SubFlat (pattern):
	var output_trie
	WalkFlat (pattern, (key, value){
		output_trie[key.strip-from-start(pattern + ".")] = value
	})
	return output_trie
SubRec (pattern):
	var output_trie
	WalkRec (pattern, (key, value){
		output_trie[key.strip-from-start(pattern + ".")] = value
	})
	return output_trie
```
