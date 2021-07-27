{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}

module Scout.Internal.Model where

import Control.Concurrent

import Optics.Extra

import Scout

data Model
    = Model { cursorOffset :: Int
            , program :: Program
            , errors :: [Error]
            , evaluated :: Program
            , evalThreadId :: Maybe ThreadId
            }
    deriving ( Show, Eq )

makeFieldLabelsWith noPrefixFieldLabels ''Model
