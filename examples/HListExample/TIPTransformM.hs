{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE MultiParamTypeClasses, FlexibleInstances #-}
{-# LANGUAGE ScopedTypeVariables, UndecidableInstances #-}
{-# LANGUAGE TypeFamilies #-}  -- !TF
-- Transforming a TIP: applying to a TIP a (polyvariadic) function
-- that takes arguments from a TIP and updates the TIP with the result.
-- The monadic version.
-- This file contains two versions of the code.
-- The comments -- !Simple and -- !TF distinguish the versions
--
-- In more detail: we have a typed-indexed collection TIP and we
-- would like to apply a transformation function to it, whose argument
-- types and the result type are all in the TIP. The function should locate
-- its arguments based on their types, and update the TIP
-- with the result. The function may have any number of arguments,
-- including zero; the order of arguments should not matter.

-- The problem was posed by Andrew U. Frank on Haskell-Cafe, Sep 10, 2009.
-- http://www.haskell.org/pipermail/haskell-cafe/2009-September/066217.html
-- The problem is an interesting variation of the keyword argument problem.
-- In March 2010, Andrew Frank extended the problem for monadic operations.
-- This is the monadic version of TIPTransform.hs in the present directory.


module HListExample.TIPTransformM where

import Data.HList.CommonMain
import Data.Typeable
import Control.Monad.Identity
import Control.Monad.Writer

import Test.Hspec
import Properties.Common

-- We start with the examples

newtype MyVal = MyVal Int deriving (Show,Typeable)

-- A specialized version of return for the Identity monad.
-- It is needed only for the Simple version of the code,
-- to tell the type checker the monad in which the computation is
-- taking place.
-- For the TF version of the code, we can use the ordinary return
-- in place of retI.
retI :: a -> Identity a
retI = return

-- A sample TIP
tip1 = MyVal 20 .*. (1::Int) .*. True .*. (3.5::Float) .*. emptyTIP
-- TIP (HCons (MyVal 20) (HCons 1 (HCons True (HCons 3.5 HNil))))

-- Update the Int component of tip1 to 2. The Int component must
-- exist. Otherwise, it is a type error
-- tip2 = runIdentity $ ttipM (retI (2::Int)) tip1 -- !Simple
tip2 = runIdentity $ ttipM (return (2::Int)) tip1  -- !TF
-- TIP (HCons (MyVal 20) (HCons 2 (HCons True (HCons 3.5 HNil))))


-- Negate the boolean component of tip1
-- tip3 = runIdentity $ ttipM (retI . not) tip1 -- !Simple
tip3 = runIdentity $ ttipM (return . not) tip1      -- !TF
-- TIP (HCons (MyVal 20) (HCons 1 (HCons False (HCons 3.5 HNil))))

-- Update the Int component from the values of two other components
tip4 = runIdentity $ ttipM (\(MyVal x) y -> retI $ x+y) tip1
-- TIP (HCons (MyVal 20) (HCons 21 (HCons True (HCons 3.5 HNil))))

-- Update the MyVal component from the values of three other components
tip5 = runIdentity $ 
       ttipM (\b (MyVal x) y -> retI $ MyVal $ if b then x+y else 0) tip1
-- TIP (HCons (MyVal 21) (HCons 1 (HCons True (HCons 3.5 HNil))))

-- The same but with the permuted argument order.
-- The order of arguments is immaterial: the values will be looked up using
-- their types
tip5' = runIdentity $ 
        ttipM (\b y (MyVal x)-> retI $ MyVal $ if b then x+y else 0) tip1
-- TIP (HCons (MyVal 21) (HCons 1 (HCons True (HCons 3.5 HNil))))

-- Andrew Frank's test
-- tip6 :: IO (TIP (HCons MyVal (HCons Int (HCons Bool (HCons Float HNil)))))
tip6 :: IO (TIP (TagR [MyVal,Int,Bool, Float]))
tip6 = ttipM op6 tip1

op6 :: MyVal -> Bool -> IO MyVal
op6 (MyVal x) b = do
                let m = if b then MyVal (x `div` 4) else MyVal (x * 4)
                putStrLn $ "MyVal is now " ++ show m
                            -- ==>> MyVal 5
                return m
-- TIP (HCons (MyVal 5) (HCons 1 (HCons True (HCons 3.5 HNil))))


op6w :: MyVal -> Bool -> Writer String MyVal
op6w (MyVal x) b = do
                let m = if b then MyVal (x `div` 4) else MyVal (x * 4)
                tell ("MyVal is now " ++ show m)
                            -- ==>> MyVal 5
                return m


{-  -- !Simple
-- The Simple implementation
-- The drawback is the need to let the type checker know the monad in which the
-- computations take place. That is why we had to use retI in the above
-- code, which is a specialized version of return for the Identity monad. 
-- In op6, the presence of putStrLn unambiguously specified the monad, viz. IO,
-- so no special return are required.

class Monad m => TransTIPM m op db where
    ttipM :: op -> db -> m db

-- If the operation is the computation in the desired monad,
-- the type of the computation must match an element of TIP.
instance (Monad m,
	  HTypeIndexed db, HUpdateAtHNat n op db db, HType2HNat op db n)
    => TransTIPM  m (m op) (TIP db) where
    ttipM op db = do
                     op' <- op
		     return $ tipyUpdate op' db

-- If op is not a computation in the desired monad m, 
-- it must be a function. Look up its argument in a TIP and recur.
instance (Monad m, HOccurs arg db, TransTIPM m op db)
    => TransTIPM m (arg -> op) db where
    ttipM f db = ttipM (f (hOccurs db)) db
-} -- !Simple

-- {- -- !TF
-- Moved to TIP.hs
-- -} -- !TF

mainTTIPM = describe "ttipM" $ it "all" $ do
  tip1 `shouldShowTo` "TIPH[MyVal 20,1,True,3.5]"
  tip2 `shouldShowTo` "TIPH[MyVal 20,2,True,3.5]"
  tip3 `shouldShowTo` "TIPH[MyVal 20,1,False,3.5]"
  tip4 `shouldShowTo` "TIPH[MyVal 20,21,True,3.5]"
  tip5 `shouldShowTo` "TIPH[MyVal 21,1,True,3.5]"
  let tip6w = runWriter (ttipM op6w tip1)
  fst tip6w `shouldShowTo` "TIPH[MyVal 5,1,True,3.5]"
  snd tip6w `shouldBe` "MyVal is now MyVal 5"

