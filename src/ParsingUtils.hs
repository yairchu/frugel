module ParsingUtils where

import           Text.Megaparsec
import qualified Data.Set        as Set
import           Prettyprinter

data Parenthesis = Left | Right
    deriving ( Eq, Ord, Show )

instance Pretty Parenthesis where
    pretty ParsingUtils.Left = lparen
    pretty ParsingUtils.Right = rparen

literalToken :: MonadParsec e s m => Token s -> m (Token s)
literalToken c = token (guarded (== c)) (one . Tokens . one $ c)

namedToken :: MonadParsec e s m => String -> (Token s -> Maybe a) -> m a
namedToken name test = token test Set.empty <?> name
