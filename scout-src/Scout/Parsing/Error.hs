-- Error formatting helpers copied from megaparsec, but modified for returning Doc's instead of strings
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeApplications #-}

{-# OPTIONS_GHC -Wno-orphans #-}

module Scout.Parsing.Error where

import qualified Data.List.NonEmpty as NE
import qualified Data.Set as Set

import Frugel.DisplayProjection

import Optics

import Scout.Node

import qualified Text.Megaparsec as Megaparsec
import Text.Megaparsec.Error
    hiding ( ParseError, errorOffset, parseErrorPretty, parseErrorTextPretty )
import Text.Megaparsec.Pos

type ParseError = Megaparsec.ParseError CstrSite ScoutParseError

newtype ScoutParseError = ConsumedEmptyCstrSite String
    deriving ( Eq, Show, Ord )

makePrisms ''Megaparsec.ParseError

makePrisms ''ErrorFancy

makePrisms ''ScoutParseError

instance DisplayProjection ParseError where
    renderDoc = parseErrorPretty

errorOffset :: Lens' (Megaparsec.ParseError s e) Int
errorOffset = lens Megaparsec.errorOffset $ flip setErrorOffset

-- | Pretty-print a 'ParseError'. The rendered 'Doc Annotation ' always ends with a
-- newline.
parseErrorPretty :: ParseError -> Doc Annotation
parseErrorPretty e
    = "offset="
    <> show (Megaparsec.errorOffset e)
    <> ":"
    <> line
    <> parseErrorTextPretty e

-- | Pretty-print a textual part of a 'ParseError', that is, everything
-- except for its position. The rendered 'Doc Annotation ' always ends with a
-- newline.
--
-- @since 5.1.0
parseErrorTextPretty :: ParseError -> Doc Annotation
parseErrorTextPretty (TrivialError _ us ps)
    = if isNothing us && Set.null ps
      then "unknown parse error"
      else messageItemsPretty
          "unexpected"
          (showErrorItem
           <$> maybe (error "Internal logic error: missing expected item")
                     one
                     us)
          <> line
          <> messageItemsPretty "expecting"
                                (showErrorItem <$> fromList (toList ps))
parseErrorTextPretty (FancyError offset xs)
    = if Set.null xs
      then "unknown fancy parse error"
      else vsep (showErrorFancy offset <$> Set.toAscList xs)

-- | Pretty-print an 'ErrorItem'.
showErrorItem :: ErrorItem (Either Char Node) -> Doc Annotation
showErrorItem = \case
    Tokens ts -> renderDoc @CstrSite $ fromFoldable ts
    Label label -> pretty $ toList label
    EndOfInput -> "end of input"

-- | Pretty-print an 'ErrorFancy'.
showErrorFancy :: Int -> ErrorFancy ScoutParseError -> Doc Annotation
showErrorFancy offset = \case
    ErrorFail msg -> pretty msg
    ErrorIndentation ord' ref actual -> "incorrect indentation (got "
        <> show (unPos actual)
        <> ", should be "
        <> p
        <> show (unPos ref)
        <> ")"
      where
        p = case ord' of
            LT -> "less than "
            EQ -> "equal to "
            GT -> "greater than "
    ErrorCustom (ConsumedEmptyCstrSite nodeName) -> parseErrorTextPretty
        $ TrivialError offset
                       (Just . Label $ fromList "an empty construction site")
                       (one . Label $ fromList nodeName)

-- | Transforms a list of error messages into their textual representation.
messageItemsPretty ::
    -- | Prefix to prepend
    Doc Annotation -> NonEmpty (Doc Annotation) -> Doc Annotation
messageItemsPretty prefix ts | null ts = ""
                             | otherwise = prefix `nestingLine` orList ts

-- | Print a pretty list where items are separated with commas and the word
-- “or” according to the rules of English punctuation.
orList :: NonEmpty (Doc Annotation) -> Doc Annotation
orList (x :| []) = x
orList (x :| [y]) = x <> " or " <> y
orList xs
    = fillCat (punctuate ", " (toList $ NE.init xs)) <> ", or " <> last xs
