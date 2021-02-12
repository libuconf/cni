# CNI
The CoNfiguration Initialization format.

CNI is an alternative configuration format.
It is a pure string -> string kv, with the keys being limited to alphanumerics, `-`, `_` and `.`.
This means that all keys are compatible with typing in the command line.
This is useful for querying, but also for compatibility with command line flags.

Furthermore, CNI is intended to be a superset of ini, but with an actual (non-divergent) specification.
It also allows for optional extensions on top of the core language (and ini-compatibility features),
so it can be expanded by users, without breaking compatibility otherwise.

This repository is the reference implementation of the CNI grammar, as well as a testing suite for other implementations.
It also provides a suggested set of APIs implementations should provide, but these are only suggestions.

The rest of this document will describe the format, decisions made, as well as possible use-cases.

## CNI Format
CNI documents greatly resemble INI documents.
If you know INI, you know enough to get started with CNI.
The rest of this section will provide a rough overview of CNI,
though reading the reference grammar (in `Grammar.pm6`, I promise it's short) should give you a more detailed idea.

Fundamentally, CNI is a list of key-value pairs.
Keys are alphanumerics, alongside a few common symbols
(dashes and underscores, as well as dots, though a key may not start or end in a dot).

Values are either barewords or raw values.
Barewords end with the line, or right before a comment starts.
They may contain any characters besides vertical spaces and comment characters.
They also may not start with a grave accent (\` also known as the backquote), because that is the marker of a raw value.
Raw values start and end with a grave accent (\`) and may contain any characters but the grave accent.
To put a grave accent inside of a raw value, simply place two of them next to each other (the first will escape the second).

Values may be separated by sections, as in ini.
A section's contents are just a key, and follows the same rules.
Any kv pair inside of the section shall have its key prefaced by the section key and a separating dot.
An empty section will reset the prefix to nothing.

Comments start with a `#` character, or a `;` character (for ini-compatibility).

For an example, please see the `bundle` directory in side of the tests directory.
`core.cni` represents the expected typical usage of cni.
`exotic.cni` represents the various quirks that the reference implementation is capable of.

The other test directories define the core language that all implementations must provide (`core`),
the ini compatibility features all implementations should provide (`ini`),
as well as the known extensions / features that are entirely optional (`ext`).

## Use Cases
Under what circumstances should you use CNI instead of something else?
Here are a few examples.

### INI User
If you currently use INI, you have certainly noticed that it has some significant limitations.
The format is entirely non-standard, and has no tooling whatsoever (due to the lack of a specification).
Users cannot run any program to validate the file, for instance, and therefore your application must provide error handling.
Further, the API is wildly different between different platforms and languages.

CNI has a strict specification, and has a recommended API.
This allows for the possibility of creating convenient tooling, and should provide some degree of interop between environments.
Further, it should be a superset of INI, meaning you should be able to simply plug it in.

It also has some advantages to your users.
Once they know they're using a superset, they gain access to useful CNI features,
such as in-line comments and raw values.

### JSON/YAML/TOML User
JSON, YAML, and TOML are common configuration file formats.
However, users often complain that these formats are somewhat unwieldy, difficult to parse and write quickly for humans.
CNI was built from the ground up to be close to the most user-friendly configuration format of all time (INI),
while delivering on significant technological improvements.

Further, YAML and TOML APIs are commonly painful to work with.
CNI provides a recommended API that should serve most use-cases, while being maximally convenient to the developer.

It's also impossible to extend any of these formats.
CNI allows for custom extensions, and I am open for registering some of them in the specification / test suite,
though don't expect the reference implementation to be modified to add them in.

It's also a very simple format, meaning that if you so desire, you can fork it yourself,
making your extensions part of the core language.

### Configuration Unification
CNI was made in the process of creating a configuration unification library.
The idea is that all configuration can be exposed via
command line arguments, configuration files, and environment variables,
not leaving any of them behind.

The key restrictions of CNI means that it's trivial to translate to and from all of these different formats.

## Counter Use-Cases
Under what circumstances should you *not* use CNI?
Here are a few examples.

### Structured Data
CNI only provides a kv database-like.

If you require highly structured data, and intend for all of your data to be like that,
having to use a separate/dedicated API to generate all of the structures
(instead of simply having it be pre-done for you) is a bit of a pain.
Since CNI does not provide any structure (besides categories for the keys) in the specification,
the standard tooling cannot warn the users about the structure of their configuration being wrong,
limiting the usefulness of this standardization.

### Data Types
CNI only allows string keys and string values.
If you have no intention of doing configuration unification (see above),
which would imply you already have the tooling to parse the string values into whatever you need,
there's no point in using a format that doesn't do format error detection or parsing.

In most cases, this isn't a huge concern
(as error reporting will need to be done on the application side anyway),
but if your configuration primarily features things such as dates
and you want the format detection and parsing to be done for you,
CNI may not be for you.

### XDG Desktop Files
FreeDesktop's xdg-desktop specification specifies using `;` as a value delimeter.
For example: `key = value1;value2;value3; ; comment only starts here`.

This is an example of various INI variants being divergent.
It would make the grammar significantly more complex to implement this, and would break compatibility with other ini-likes.
The XDG specification also includes escaping `;`s.

If you want to parse XDG Desktop files, you should use a parser made for them, and not CNI.

## FAQ
### Pronunciation
"How do I pronounce CNI?!"

It is correct to pronounce CNI as "seenie" (similar to "innie" for INI) or as "see-enn-aye" (letter by letter).
Both of these are correct, and neither is preferred.

### Reference Compliance
"What is the compliance level of the reference implementation?"

* `core`: compliant.
* `ini`: compliant.
* `ext`: flexspace, tabulation.
