{-# LANGUAGE FlexibleContexts #-}
{-
   (C) 2004, Oleg Kiselyov, Ralf Laemmel, Keean Schupke

   Some dedicated infix operators at the type and the value level.
-}

module Data.HList.GhcSyntax where

import Data.HList.HArray (HUpdateAtHNat())
import Data.HList.FakePrelude
import Data.HList.HListPrelude
import Data.HList.HOccurs
import Data.HList.Record
import Data.HList.GhcRecord
import Data.HList.TIP
import Data.HList.TIC


{-----------------------------------------------------------------------------}

-- Convenience notation for type sequences

infixr 2 :*:
infixr 2 .*.

type e :*: l = HCons e l

(.*.) :: HExtend e l l' => e -> l -> l'
(.*.) =  hExtend


{-----------------------------------------------------------------------------}

-- Convenience notation for records

infixr 4 :=:
type l :=: v = LVPair l v

infixr 4 .=.
(.=.) :: l -> v -> LVPair l v
l .=. v = newLVPair l v

infixr 3 .!.
(.!.) :: (HasField l r v) => r -> l -> v
r .!. l =  hLookupByLabel l r

infixl 1 .-.
(.-.) :: (H2ProjectByLabels (HCons e HNil) t t1 t2) => Record t -> e -> Record t2
r .-. l =  hDeleteAtLabel l r

infixl 1 .@.
(.@.) :: (HUpdateAtHNat n (LVPair t t1) t2 l',
         HFind t ls n,
         RecordLabels t2 ls) =>
        Record t2 -> LVPair t t1 -> Record l'
r .@. f@(LVPair v) =  hUpdateAtLabel (labelLVPair f) v r

infixr 1 .^.
(.^.) :: (HasField t t2 (Proxy t1),
         RecordLabels t2 ls,
         HFind t ls n,
         Data.HList.HArray.HUpdateAtHNat n (LVPair t t1) t2 l') =>
         LVPair t t1 -> Record t2 -> Record l'
f@(LVPair v) .^. r = hUnproxyLabel (labelLVPair f) v r

infixr 1 .<.
(.<.) :: (HasField t t2 t1,
         RecordLabels t2 ls,
         HFind t ls n,
         HUpdateAtHNat n (LVPair t t1) t2 l') =>
        LVPair t t1 -> Record t2 -> Record l'
f@(LVPair v) .<. r = hTPupdateAtLabel (labelLVPair f) v r

infixl 1 .<++.
(.<++.) :: (HLeftUnion r r' r'') => r -> r' -> r''
r .<++. r' = hLeftUnion r r'


{-----------------------------------------------------------------------------}

-- Convenience notation for TIRs

infixr 2 :+:
infixr 2 .+.

type e :+: l = HCons (Proxy e) l

(.+.) :: ( HTypeIndexed l
         , HTypeProxied l
         , HOccursNot (Proxy e) l
         )
      => e -> TIP l -> TIP (HCons (Proxy e) l)
e .+. r = hExtend (toProxy e) r


{-----------------------------------------------------------------------------}