module Trie exposing
    ( Node(..)
    , Trie
    , empty
    , fromDict
    , get
    , insert
    , internal
    , member
    , remove
    , size
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
            insertHelper chars value node
    in
    Trie newNode


insertHelper : List Char -> a -> Node a -> Node a
insertHelper chars value (Node mval dict) =
    case chars of
        [] ->
            Node (Just value) dict

        head :: tail ->
            let
                updateDict m =
                    m
                        |> Maybe.withDefault emptyNode
                        |> insertHelper tail value
                        |> Just
            in
            Node mval (Dict.update head updateDict dict)


remove : String -> Trie a -> Trie a
remove key (Trie node) =
    let
        chars =
            String.toList key
    in
    removeHelper chars node
        |> Maybe.withDefault emptyNode
        |> Trie


removeHelper : List Char -> Node a -> Maybe (Node a)
removeHelper chars (Node mval dict) =
    case chars of
        [] ->
            if Dict.isEmpty dict then
                Nothing

            else
                Just (Node Nothing dict)

        head :: tail ->
            let
                newDict =
                    Dict.update
                        head
                        (Maybe.withDefault emptyNode >> removeHelper tail)
                        dict
            in
            if Dict.isEmpty newDict && mval == Nothing then
                Nothing

            else
                Just (Node mval newDict)


member : String -> Trie a -> Bool
member key (Trie node) =
    memberHelper (String.toList key) node


memberHelper : List Char -> Node a -> Bool
memberHelper chars (Node mval dict) =
    case chars of
        [] ->
            case mval of
                Nothing ->
                    False

                Just _ ->
                    True

        head :: tail ->
            Dict.get head dict
                |> Maybe.map (memberHelper tail)
                |> Maybe.withDefault False


size : Trie a -> Int
size (Trie node) =
    sizeHelp node 0


sizeHelp : Node a -> Int -> Int
sizeHelp (Node mval dict) acc =
    let
        content =
            case mval of
                Nothing ->
                    0

                Just _ ->
                    1
    in
    content + Dict.foldl (always sizeHelp) acc dict


get : String -> Trie a -> Maybe a
get key (Trie node) =
    getHelper (String.toList key) node


getHelper : List Char -> Node a -> Maybe a
getHelper chars (Node mval dict) =
    case chars of
        [] ->
            mval

        head :: tail ->
            Dict.get head dict
                |> Maybe.andThen (getHelper tail)


internal : Trie a -> Node a
internal (Trie node) =
    node


{-| Create a Trie from a Dictionary
-}
fromDict : Dict String a -> Trie a
fromDict dict =
    Dict.foldl insert empty dict
