module Parser.Dict exposing (fromDict)

{-|

@docs fromDict

-}

import Dict exposing (Dict)
import Parser exposing ((|.), (|=), Parser, Step(..))
import Trie exposing (Node(..), Trie)


{-| Create a fast parser for a dictionary.

The parser succeeds with the longest matching key

    type Animal
        = Dog
        | Cat
        | Horse

    animal : Parser Animal
    animal =
        [ ( "doggo", Dog )
        , ( "kitty", Cat )
        , ( "horsey", Horse )
        ]
            |> Dict.fromList
            |> fromDict

-}
fromDict : Dict String a -> Parser a
fromDict dict =
    let
        (Node _ nodeDict) =
            dict
                |> Trie.fromDict
                |> Trie.internal

        topNode =
            Node Nothing nodeDict
    in
    Parser.succeed (startParsing topNode)
        |= Parser.getSource
        |= Parser.getOffset
        |> Parser.andThen handleMatched


handleMatched : Maybe (Match a) -> Parser a
handleMatched mMatch =
    case mMatch of
        Nothing ->
            Parser.problem "Unable to parse string"

        Just (Match value matchLength) ->
            chomp matchLength
                |> Parser.map (always value)


startParsing : Node a -> String -> Int -> Maybe (Match a)
startParsing topNode source offset =
    let
        str =
            String.dropLeft offset source
    in
    findLongestMatch str Nothing 0 topNode


{-| Matched value and offset
-}
type Match a
    = Match a Int


findLongestMatch : String -> Maybe (Match a) -> Int -> Node a -> Maybe (Match a)
findLongestMatch source mLastMatch offset (Node mMatch dict) =
    let
        newMatch =
            case mMatch of
                Nothing ->
                    mLastMatch

                Just value ->
                    Just <| Match value offset
    in
    case String.uncons source of
        Nothing ->
            --Nothing more to parse
            newMatch

        Just ( char, rest ) ->
            case Dict.get char dict of
                Just node ->
                    findLongestMatch rest newMatch (offset + 1) node

                Nothing ->
                    newMatch


{-| Chomps n characters
-}
chomp : Int -> Parser ()
chomp n =
    Parser.loop n chompHelp


chompHelp : Int -> Parser (Step Int ())
chompHelp n =
    if n > 30 then
        chompDirectly 30 (Loop <| n - 30)

    else
        chompDirectly n (Done ())


{-| May overflow the stack if n is too big
-}
chompDirectly : Int -> a -> Parser a
chompDirectly n a =
    List.repeat n chompOne
        |> List.foldl (flip (|.)) (Parser.succeed a)


chompOne : Parser ()
chompOne =
    Parser.chompIf (always True)


flip : (a -> b -> c) -> b -> a -> c
flip f b a =
    f a b
