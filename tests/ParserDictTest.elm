module ParserDictTest exposing (suite)

import Dict exposing (Dict)
import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer)
import Parser exposing ((|.), (|=), Parser)
import Parser.Dict as DictParser
import Test exposing (Test, describe, fuzz, test)


suite : Test
suite =
    describe "DictParser"
        [ fuzz
            (Fuzz.tuple ( acceptableKey, stringDict ))
            "can match any arbitrary key"
          <|
            \( aName, dict ) ->
                dict
                    |> insertAsKeyAndValue aName
                    |> matchEachEntry DictParser.fromDict
        , test "succeeds with the longest match" <|
            \_ ->
                Dict.empty
                    |> insertAsKeyAndValue "a"
                    |> insertAsKeyAndValue "ab"
                    |> insertAsKeyAndValue "abc"
                    |> insertAsKeyAndValue "abcd"
                    |> insertAsKeyAndValue "abcde"
                    |> matchEachEntry DictParser.fromDict
        , test "matches only from the start of the string" <|
            \_ ->
                Dict.empty
                    |> insertAsKeyAndValue "aria"
                    |> DictParser.fromDict
                    |> (\parser -> parse parser "maria")
                    |> Expect.equal Nothing
        , test "fails if matching is incomplete" <|
            \_ ->
                Dict.empty
                    |> insertAsKeyAndValue "maria"
                    |> DictParser.fromDict
                    |> (\parser -> parse parser "mar")
                    |> Expect.equal Nothing
        , test "backtracks success" <|
            \_ ->
                Dict.empty
                    |> insertAsKeyAndValue "123"
                    |> insertAsKeyAndValue "12345678"
                    |> DictParser.fromDict
                    |> (\parser -> parse parser "12345")
                    |> Expect.equal (Just "123")
        , test "backtracks success returning parsing to correct position" <|
            \_ ->
                Dict.empty
                    |> insertAsKeyAndValue "123"
                    |> insertAsKeyAndValue "12345678"
                    |> insertAsKeyAndValue "456"
                    |> DictParser.fromDict
                    |> (\parser ->
                            Parser.succeed (\a b -> [ a, b ])
                                |= parser
                                |= parser
                       )
                    |> (\listParser -> parse listParser "1234567")
                    |> Expect.equal (Just [ "123", "456" ])
        ]


{-| Acceptable string keys are:

  - not empty
  - up to 500 characters

-}
acceptableKey : Fuzzer String
acceptableKey =
    let
        fuzzChar =
            Fuzz.char
                |> Fuzz.map String.fromChar

        nonempty =
            Fuzz.map2 (++) fuzzChar Fuzz.string
    in
    nonempty
        |> Fuzz.map (String.left 500)


{-| Tries to match all dictionary entries
-}
matchEachEntry : (Dict String String -> Parser String) -> Dict String String -> Expectation
matchEachEntry fromDict dict =
    let
        parser =
            fromDict dict
    in
    Dict.keys dict
        |> List.filterMap (\name -> parse parser name)
        |> Expect.equal (Dict.keys dict)


parse : Parser a -> String -> Maybe a
parse parser str =
    Parser.run parser str
        |> Result.map Just
        |> Result.withDefault Nothing


stringDict : Fuzzer (Dict String String)
stringDict =
    Fuzz.list acceptableKey
        |> Fuzz.map (List.map (\n -> ( n, n )))
        |> Fuzz.map Dict.fromList


insertAsKeyAndValue : String -> Dict String String -> Dict String String
insertAsKeyAndValue key dict =
    Dict.insert key key dict
