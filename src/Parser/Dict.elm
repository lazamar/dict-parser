module Parser.Dict exposing (fromDict)

{-| Create a fast parser from a dictionary


## Create

@docs fromDict

-}

import Dict exposing (Dict)
import Parser exposing ((|.), (|=), Parser, Step(..))
import Trie exposing (Node(..), Trie)


{-| Create a parser from a dictionary
-}
fromDict : Dict String a -> Parser a
fromDict dict =
    let
        (NodeT _ nodeDict) =
            dict
                |> Trie.fromDict
                |> Trie.internal
                |> toNodeT
    in
    loop (NodeT Nothing nodeDict)


{-| Describes a Trie where keys are of type String instead of Char.
Even though theses strings still have only one character, having them
with type String makes the parsing checks faster.
-}
type NodeT a
    = NodeT (Maybe a) (Dict String (NodeT a))


toNodeT : Node a -> NodeT a
toNodeT (Node mval dict) =
    dict
        |> Dict.toList
        |> List.map (\( char, node ) -> ( String.fromChar char, toNodeT node ))
        |> Dict.fromList
        |> NodeT mval


loop : NodeT a -> Parser a
loop (NodeT mLastMatch dict) =
    let
        nextParser =
            Parser.andThen
                (toNextLevel dict)
                chompOne
    in
    case mLastMatch of
        Nothing ->
            nextParser

        Just value ->
            Parser.oneOf
                [ Parser.backtrackable nextParser
                , Parser.succeed value
                ]


chompOne : Parser String
chompOne =
    Parser.getChompedString <| Parser.chompIf (always True)


toNextLevel : Dict String (NodeT a) -> String -> Parser a
toNextLevel dict str =
    case Dict.get str dict of
        Nothing ->
            Parser.problem "Value not found in dictionary"

        Just node ->
            loop node
