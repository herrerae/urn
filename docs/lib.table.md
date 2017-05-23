---
title: table
---
# table
## `(.<! x &keys value)`
*Macro defined at lib/table.lisp:92:1*

Set the value at `KEYS` in the structure `X` to `VALUE`.

## `(.> x &keys)`
*Macro defined at lib/table.lisp:86:1*

Index the structure `X` with the sequence of accesses given by `KEYS`.

## `(assoc list key or-val)`
*Defined at lib/table.lisp:11:1*

Return the value given by `KEY` in the association list `LIST`, or, in the
case that it does not exist, the value `OR`-`VAL`, which can be nil.

## `(assoc->struct list)`
*Defined at lib/table.lisp:47:1*

Convert the association list `LIST` into a structure. Much like
[`assoc`](lib.table.md#assoc-list-key-or-val), in the case there are several values bound to the same key,
the first value is chosen.

## `(assoc? list key)`
*Defined at lib/table.lisp:22:1*

Check that `KEY` is bound in the association list `LIST`.

## `(create-lookup values)`
*Defined at lib/table.lisp:177:1*

Convert `VALUES` into a lookup table, with each value being converted to
a key whose corresponding value is the value's index.

## `(empty-struct? xs)`
*Defined at lib/table.lisp:138:1*

Check that `XS` is the empty struct.

## `(extend ls key val)`
*Defined at lib/table.lisp:37:1*

Extend the association list `LIST`_ by inserting `VAL`, bound to the key
`KEY`, overriding any previous value.

## `(fast-struct &entries)`
*Defined at lib/table.lisp:125:1*

`A` variation of [`struct`](lib.table.md#struct-entries), which will not perform any coercing of the
`KEYS` in entries.

Note, if you know your values at compile time, it is more performant
to use a struct literal.

## `(for-pairs vars tbl &body)`
*Macro defined at lib/table.lisp:148:1*

Iterate over `TBL`, binding `VARS` for each key value pair in `BODY`

## `(insert list_ key val)`
*Defined at lib/table.lisp:32:1*

Extend the association list `LIST`_ by inserting `VAL`, bound to the key
`KEY`.

## `(insert! list_ key val)`
*Defined at lib/table.lisp:42:1*

Extend the association list `LIST`_ in place by inserting `VAL`, bound to
the key `KEY`.

## `iter-pairs`
*Native defined at lib/lua/table.lisp:8:1*

Iterate over `TABLE` with a function `FUNC` of the form (lambda (`KEY` `VAL`) ...)

## `(keys st)`
*Defined at lib/table.lisp:160:1*

Return the keys in the structure `ST`.

## `(merge &structs)`
*Defined at lib/table.lisp:152:1*

Merge all tables in `STRUCTS` together into a new table.

## `(nkeys st)`
*Defined at lib/table.lisp:142:1*

Return the number of keys in the structure `ST`.

## `(struct &entries)`
*Defined at lib/table.lisp:100:1*

Return the structure given by the list of pairs `ENTRIES`. Note that, in
contrast to variations of [`let`](lib.binders.md#let-vars-body), the pairs are given "unpacked":
Instead of invoking

```cl
(struct [(:foo bar)])
```
or
```cl
(struct {:foo bar})
```
you must instead invoke it like
```cl
(struct :foo bar)
```

## `(struct->assoc tbl)`
*Defined at lib/table.lisp:63:1*

Convert the structure `TBL` into an association list. Note that
`(eq? x (struct->assoc (assoc->struct x)))` is not guaranteed,
because duplicate elements will be removed.

## `(struct->list tbl)`
*Defined at lib/table.lisp:72:1*

Converts a structure `TBL` that is a list by having its keys be indices
to a regular list.

## `(struct->list! tbl)`
*Defined at lib/table.lisp:78:1*

Converts a structure `TBL` that is a list by having its keys be indices
to a regular list. This differs from `struct->list` in that it mutates
its argument.

## `(update-struct st &keys)`
*Defined at lib/table.lisp:172:1*

Create a new structure based of `ST`, setting the values given by the
pairs in `KEYS`.

## `(values st)`
*Defined at lib/table.lisp:166:1*

Return the values in the structure `ST`.

## Undocumented symbols
 - `getmetatable` *Native defined at lib/lua/basic.lisp:28:1*
 - `len#` *Native defined at lib/lua/basic.lisp:19:1*
 - `next` *Native defined at lib/lua/basic.lisp:32:1*
 - `setmetatable` *Native defined at lib/lua/basic.lisp:44:1*