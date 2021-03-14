# CNI Specification
Note that the prime source of information about CNI is to be considered the reference implementation and test suite.
This document is a reading companion (rather than the source of truth) that should help expediate the development of implementations.

## Core Language
A CNI document consists of an arbitrary amount of statements.
A statement may either be a section declaration, key-value pair, or key-rawvalue pair.
Whitespace between elements is not significant, meaning that unless it would be consumed otherwise (such as in a value of a key-value pair), it may be inserted whenever.
This obviously includes empty lines, as well as prepending statements with whitespace, though more uses will be mentioned later.

Note: some technically valid syntax is discouraged. Have a read through the test suite to see what is discouraged.
Note: a comment does not count as whitespace.
Note: it is valid to have multiple statements assigning to the same key.
In the event this happens, the last key definition wins.
For example,
```
sub.source = main.zip
[sub]
source = src.zip
```
will result in the `sub.source` key having the value of `src.zip`.

### Key
A key is composed of alphanumeric (`[a-zA-Z0-9]`) characters, underscores, and dashes.
Keys may contain dots, but may not start or end with them - dots semantically signify sections.
Two dots in a row are disallowed (due to being nonsensical, it would imply a section with no name), but implementations do not need to explicitly disallow them.

### Section Declaration
A section consists of an opening bracket (`[`), the section name, and a closing bracket (`]`).
The section name may either be a valid key, or empty.

Until the next section, all keys will be automatically prepended the section name and a `.`, or with nothing (if the section name is the empty string).
Note that there may be any amount of whitespace in between the section name and the brackets.

### Key-(Raw)Value Pairs
A key-value and key-rawvalue pair look very similar.
It's a key, an equals, and a value, with arbitrary amounts of whitespace before and after the `=`.

A value may contain any UTF-8 characters except vertical whitespace or the `#` sign (note: this is expanded upon in ini-compatibility).
It may not start or end with whitespace, or start with a backtick.

A rawvalue starts with a backtick and ends with a backtick, but may contain any UTF-8 characters besides those.
If a backtick needs to be inserted into a raw value, a backtick may be escaped with a second one.

After both a value and a rawvalue, you may have any amount of horizontal whitespace before a comment or the end of the line.
Vertical whitespace is excluded, since that would imply the statement has ended.

Theoretically, this means that both values and raw values may contain arbitrary bytes, but the specification is exclusively intended to be used with UTF-8 data.
Implementations are not required to validate it, though.

### Comments
A comment starts with a `#` (note: this is expanded upon in ini-compatibility) and ends at the next vertical whitespace.
A comment may start on its own line, at any point "inside" of a value (thus ending it), after a section declaration, or after a raw value.
It is impossible to have comments inside of a raw value, or inside of a section declaration.

## Ini-Compatibility
For compatibility with INI, the `;` character may also be used for comments, i.e treated as if it were a `#`.

## Extensions
All extensions are fully optional:
* They are not part of "CNI", but are to be considered common extensions library authors may choose to add into their libraries, or application authors choose to make use of.
* Library authors may implement any amount of extensions they wish.
* Application authors should only mention any extensions that are important to the functioning of their application.
* Application end-users should not rely on any extensions being present, unless the application they use makes it clear that said extension is available.

## API
This API is purely a suggestion for the sake of users - implementations may follow any scheme they wish.

Backend storage should be implemented in a trie-like fashion, separated by `.`s.
It should be possible to get the direct list of children of a trie node, as well as the full list of children of a trie node.
It should be possible to know if a given key is a section, key, both, or neither.
It should be possible to walk over matches without requiring allocation of a new trie.
Keys do not need to be ordered in any specific way, but sorting them may make implementing the API easier.

The following API endpoints provide all of this functionality:

### Walk (Leaves|Tree)
WalkLeaves|WalkTree takes a pattern (which may be empty) and a function.
It will call the function with each matching key-(raw)value pair.
The matches are performed like so:
1. If the pattern is empty, all keys match.
2. If the pattern is an invalid key, no keys match.
3. If the pattern is a valid key:
   With the Tree variant, all keys that start with the pattern followed by a "." match.
   With the Leaves variant, all keys that start with the pattern followed by a ".", but that do not contain any additional "."s beyond those match.

### List (Leaves|Tree)
ListLeaves|ListTree takes a pattern and returns a list of values.
The list will contain all of the values (including duplicates) that match under the corresponding `Walk*` function.
It can be implemented in pseudocode using the `Walk*` functions like so:

```
ListLeaves (pattern):
	var output_list
	WalkLeaves (pattern, lambda (key, value):
		output_list.append(value)
	)
	return output_list
ListTree (pattern):
	var output_list
	WalkTree (pattern, lambda (key, value):
		output_list.append(value)
	)
	return output_list
```

### Key (Leaves|Tree)
KeyLeaves|KeyTree takes a pattern and returns a set of keys.
It is the converse of ListLeaves|ListTree.

### Sub (Leaves|Tree)
SubLeaves|SubTree takes a pattern, and constructs a new trie.
The new trie will contain all of the key-(raw)value pairs that match under the corresponding `Walk*` function, but with the pattern (and the dot immediately after it) removed.
It can be implemented in pseudocode using the `Walk*` functions like so:

```
SubLeaves (pattern):
	var output_trie
	WalkLeaves (pattern, lambda (key, value):
		output_trie[key.strip-from-start(pattern + ".")] = value
	)
	return output_trie
SubTree (pattern):
	var output_trie
	WalkTree (pattern, lambda (key, value):
		output_trie[key.strip-from-start(pattern + ".")] = value
	)
	return output_trie
```

### Section (Leaves|Tree)
SectionLeaves|SectionTree takes a pattern and returns a set of prefixes.
It can be calculated roughly as follows:
1. Get the corresponding set from KeyLeaves|KeyTree.
2. For each key in the set:
	1. If the key does not contain a `.`, continue.
	2. Remove the final `.` and all text that follows from the key (for example, `foo.bar.baz` becomes `foo.bar`).
	3. Add the result to the result set.
	4. Add the result to the set of keys to process.
3. Return the resulting set.

## Definitions
Some terms in this document may be confusing.
This section should clarify those.

### Set
A set is like a list, but cannot contain duplicate items.
For example, if I add "a" to an empty set twice, I end up with a set with one element: "a".

### Vertical Whitespace
Unlike horizontal whitespace, unicode does not provide a good definition for "vertical whitespace".
For the purposes of this document, consider it to mean the following code points:
* U+000A Line Feed (`\n`)
* U+000B Vertical Tabulation
* U+000C Form Feed
* U+000D Carriage Return (`\r`)
* U+0085 Next Line
* U+2028 Line Separator
* U+2029 Paragraph Separator

If the library implementer's language or regex engine provides its own vertical whitespace group (such as raku's `\v`), implementers are encouraged to use it instead of hardcoding the above list.
