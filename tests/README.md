# CNI Test Data

These is the canonical set of tests for CNI parsers.
Each test is represented by a `.cni` file and a corresponding `.json` file of the same basename.
The `.json` file should be equivalent to the unordered results (hash/map/etc) of parsing its corresponding cni file.

There may also be a `.md` file with the same basename that explains the test in human terms.

NOTE: the `json` file will contain a flat structure. (e.g `{"a.b": "c"}` rather than `{"a":{"b":"c"}}`).
This is the chosen representation because the CNI API works primarily as a kv (with any nested systems secondary).
The correct way to verify this is via the following pseudocode algorithm:
```
for key, value in json:
	assert myoutput[key] == value
```

Any parses that should fail will contain the string "fail" in their name..

## Categories

Further, these tests are categorized in three ways.

* `core`: these tests verify the correctness of the parser for the core of CNI, as it's intended to be used.
* `ini`: these tests verify the ini-compatibility aspects of CNI (such as using `;` for comments). They are optional.
* `ext`: these tests verify the correctness various optional official extensions to CNI.

There is also a `bundle` directory.
The tests there bundle many different features (a mix of all 3), and are nicer to test against during development.
They also serve as usage examples.

## Compliance Reporting

If you are writing an implementation, please describe its compliance as follows:
1. Compliance for `core` as a ratio (e.g X/Y tests passed, or "fully core-compliant").
2. Compliance for `ini` as a whole (only "fully ini-compliant" or "not ini compliant").
3. Compliance for `ext` per-feature (list out every extension (basename of the files) that you are conformant to).

For example:
* `core`: 29/29, `ini`: compliant, `ext`: more-keys.
* `core`: compliant, `ini`: non-compliant, `ext`: none.
* `core`: 24/29, `ini`: compliant, `ext`: more-keys.

Obviously, any implementation that is not fully core compliant should not be considered finished.

## Submitting Extensions
If your implementation has an extension on top of the core language, feel free to open a PR.
The PR should add a named feature test-case to the `ext` directory.
