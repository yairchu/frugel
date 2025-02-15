{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE ExistentialQuantification #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE UndecidableSuperClasses #-}

module Data.Constrained where

import Optics.Extra.Scout

data Constrained c = forall a. c a => Constrained a

fromConstrained :: (forall a. c a => a -> b) -> Constrained c -> b
fromConstrained f (Constrained a) = f a

_ConstrainedVL :: Functor f
    => (forall a. c a => a -> f a)
    -> Constrained c
    -> f (Constrained c)
_ConstrainedVL f (Constrained a) = Constrained <$> f a

_UnConstrained :: (Intro k is, ViewableOptic k r)
    => (forall s. c s => Optic' k is s r)
    -> Optic' k is (Constrained c) r
_UnConstrained l = intro $ \(Constrained a) -> gview l a
