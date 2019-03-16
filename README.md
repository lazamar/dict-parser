# Dict Parser

[![Build Status](https://travis-ci.org/lazamar/dict-parser.svg?branch=master)](https://travis-ci.org/lazamar/dict-parser)

Create a fast parser to match dictionary keys.

## The problem

If you need a parser to match strings that you know beforehand you could use `Parser.oneOf`.

	foodChainPiece : Parser String
	foodChainPiece = 
		Parser.oneOf
			[ Parser.backtrackable <| Parser.token "leaf"
			, Parser.backtrackable <| Parser.token "ant"
			, Parser.backtrackable <| Parser.token "anteater"
			]
			|> Parser.getChompedString

Now we can parse things in the food chain. However this parser a few problems:

- **It is slow** - It will always try all possible options regardless of how the parsed string looks like. 
- **It is inefficient** - Using `oneOf`	with `backtrackable` is [advised against](https://github.com/elm/parser/blob/master/semantics.md#backtrackable--oneof-inefficient). It means we will be chomping the same characters over and over again.
- **Order matters** - Our small example will never be able to parse `anteater` as `ant` will always be matched first.


## Implementation

[`examples/readme/`](https://en.wikipedia.org/wiki/Trie)

Trie data structure.

It is great for doing fast string matching.

Here is an example:
        Trie.empty
            |> Trie.add "john" ()
            |> Trie.add "josh" ()


                 "j" (Nothing)
                   \
                   "o" (Nothing)
                  /  \
      (Nothing) "h"   "s" (Nothing)
               /        \
    (Just ()) "n"       "h" (Just ())

## Limitations

  - not empty
  - up to 200 characters


## Benchmarks

