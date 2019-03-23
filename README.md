# Dict Parser

[![Build Status](https://travis-ci.org/lazamar/dict-parser.svg?branch=master)](https://travis-ci.org/lazamar/dict-parser)

Create fast parsers to match dictionary keys.

Succeeds with the longest matching key. Is stack safe.

## The problem

If you need a parser to match strings that you know beforehand you could use `Parser.oneOf`.

```elm
import Parser exposing (Parser, oneOf, backtrackable, token, getChompedString)

friendName : Parser String
friendName = 
	oneOf
		[ backtrackable <| token "joe"
		, backtrackable <| token "joey"
		, backtrackable <| token "john"
		]
		|> getChompedString
```

Now we can parse the name of our friends. However this parser has a few problems:

- **It is slow** - It will always try all possible options regardless of how the parsed string looks like. 
- **It is inefficient** - Using `oneOf`	with `backtrackable` is [advised against](https://github.com/elm/parser/blob/master/semantics.md#backtrackable--oneof-inefficient). It means that we will be chomping the same characters over and over again.
- **Order matters** - Small as it is, our example has a bug. It will never be able to parse *joel* as *joe* will always succeed first.


## The solution

```elm
import Parser.Dict as DictParser

friendName : Parser String
friendName =
	[ ("joe", "joe")
	, ("joey", "joey")
	, ("john", "john")
	]
		|> Dict.fromList
		|> DictParser.fromDict
```

`dict-parser` organises the data in a [Trie](https://en.wikipedia.org/wiki/Trie) to create a parser that will match strings quickly and efficiently.


                "j" 
                  \
                  "o"
                 /  \
         (joe) "e"   "h" 
               /       \
      (joey) "y"        "n" (john)


In this example, if the first character being checked is not a *j* it will already fail the parsing.

Once we get past *j* and *o* we can match either *e* or *h*. We could try them in sequence, but instead we use a dictionary with the characters at that level, allowing this check to be very fast.

## Stack safety

Great care has been taken to make sure that it doesn't matter how long your dictionary keys are, or how many of them you have, the parser will never overflow the stack.

## How fast is it?

![dict-parser-comparison](https://cdn.jsdelivr.net/gh/lazamar/dict-parser@master/images/comparisons-chart.svg)

Let's imagine that we are trying to match a word with 5 characters and we have 1000 words in our dictionary.

The time complexity of `oneOf` + `backtrackable` + `token` is of **O(n * l)**, where *l* is the length of the word being matched and *n* is the total number of words.
In the worst case scenario our example would require 5000 comparisons with this approach.

The time complexity of using a Trie and matching the possible characters sequentially at each level is of **O(n + l)**.
In the worst case scenario our example would require 1005 comparisons with this approach.

The time complexity is of this package's implementation is of **O(l * log2(n / l))**.
We use a Trie and with a Dictionary at each level to perform binary search.
In the worst case scenario our example would require 39 comparisons with this approach.
