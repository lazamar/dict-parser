module Trie exposing
    ( Node(..)
    , Trie
    , fromDict
    , internal
    )

{-|

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

-}

import Char exposing (Char)
import Dict exposing (Dict)


{-| The top node represents the empty string
-}
type Trie a
    = Trie (Node a)


type Node a
    = Node (Maybe a) (CharDict a)


type alias CharDict a =
    Dict Char (Node a)


empty : Trie a
empty =
    Trie emptyNode


emptyNode : Node a
emptyNode =
    Node Nothing Dict.empty


insert : String -> a -> Trie a -> Trie a
insert key value (Trie node) =
    let
        chars =
            String.toList key

        newNode =
            insertHelper [] chars value node
    in
    Trie newNode


{-| To avoid stack overflow we create functions that will
wait for the result of the recursive part and add all of them
to a list. Once we finished recursing we just go though the list
applying all the computed elements
-}
insertHelper : List ( Char, Node a ) -> List Char -> a -> Node a -> Node a
insertHelper nodeCreators chars value (Node mval dict) =
    case chars of
        [] ->
            joinNodes nodeCreators (Node (Just value) dict)

        head :: tail ->
            let
                nextNode =
                    case Dict.get head dict of
                        Nothing ->
                            emptyNode

                        Just node ->
                            node
            in
            insertHelper
                (( head, Node mval dict ) :: nodeCreators)
                tail
                value
                nextNode


joinNodes : List ( Char, Node a ) -> Node a -> Node a
joinNodes pres leaf =
    List.foldl (\( key, Node mval dict ) node -> Node mval <| Dict.insert key node dict) leaf pres


internal : Trie a -> Node a
internal (Trie node) =
    node


fromDict : Dict String a -> Trie a
fromDict dict =
    Dict.foldl insert empty dict
