# Overview

Ejson is an extension to JSON format. The Ejson library processes the
extensions and outputs standard JSON.

Ejson as JSON format is compatible with standard JSON, i.e. the syntax
is the same and Ejson can be processed with JSON tools. The extensions
are special Ejson keyworks that have semantics which the Ejson
processors manages.

Ejson renders the JSON database more dynamic and easy to maintain. The
same could be achieved with a separate pre-processor, but Ejson
provides tight integration to JSON. This means that JSON aware text
editors can be utilized and the JSON file (but with extensions) looks
and feels like a "normal" JSON file.


# Extensions

The extensions provide dynamic behaviour and modularity support.

* `@eval`: Evaluate "system"/"shell" command.

* `@join`: Join pieces of strings with given separator.

* `@flat`: Flatten the list by one level.

* `@self`: Refer to existing key/value pair, i.e. support for variables.

* `@over`: Overwrite existing value or create if not existing.

* `@base`: Set base (default) value, if not existing.

* `@null`: No operation.

* `@include`: Expand another Ejson/JSON file inplace.


Example:

```
    {
        "opts": [
            { "@eval": "/prj/ejson/sbin/list_opts" },
            { "@join": [ " ",
                         "-conf_file",
                         { "@join": [ "/",
                                      { "@self": "workdir" },
                                      "unit/data.txt" ] }
                       ]
            }
        ],
        "sub-defs": { "@include": "submodule.json" }
    }

```

Extension are captured with a Hash with one key/value pair. The value
will be recursively processed, and hence the extensions can be nested.

Value of "opts" is an array, and the extensions can be directly stored
as array members.

"sub-defs" gives a unique name (key) for the extension, and each key
must be unique in JSON, or it's will be silently overwritten and
disappear.

Hence depending on the context the extension is written either with or
without the extension name.

Extension arguments and results:

```
    @eval: <string>                           => <string>
    @join: <separator>, <list-of-strings>     => <string>
    @flat: <array-of-atoms-or-arrays>         => <array>
    @self: <key-reference>                    => <value>
    @over: <key-reference>, <value>           => -
    @base: <key-reference>, <value>           => -
    @null: false                              => -
    @include: <filename-string>               => <hash>

```

# Key Reference

Key Reference (KR) is a String with ":" used as hierarchy
separator. The string should start with ":" to designate the root, but
when a pure top reference is performed, then a plain key name is
accepted (e.g. "opts").

Key Reference is split into path selectors with the ":" character. The
path selectors are used one by one. Typically the path selector is a
key and the corresponding value is selected to be used for the next
path selector.

However, for arrays, the path selectors can be an index. The index
selects the nth item in the array.

In addition to selecting keys and indexed items, there is wildcard
selector. The "*" character is used as wildcard. Wildcard behaves
differently depending on its location in the Key Reference string.

If wildcard is the last part of the KR, then it must correspond to an
array in the hierarchy. The wildcard thus means all the members in the
array.

The array members must be Hash entries when KR is used with "@over" or
"@base". The value in this case is array of two, where first entry is
key for the Hash members and second entry is the assigned value.

If wildcard is in the middle of the KR, then the next two path
selectors are used as key and value matching references. Wildcard must
correspond to an array of Hash members, and member that matches the
key and value, will be selected. In allows travelling through the
array without knowing the array index of the desired member.

Example:

```
    "base-name": { "@base": [ ":modules:*", [ "start", "starter" ] ] },
    "over-name": { "@over": [ ":modules:*:name:main:stop", "stopper" ] },
```
