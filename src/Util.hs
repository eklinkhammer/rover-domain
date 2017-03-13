{-# LANGUAGE BangPatterns #-}

module Util
  (
    randomRoverDomain
  , repIO
  , randomN
  ) where

import System.Random
import qualified Data.Map.Strict as Map

import Models.POI
import Models.Rover
import Models.RoverDomain
import Models.State

import NN.NeuralNetwork

import Data.List (mapAccumL)                         

randomN :: RandomGen g => Int -> g -> (g -> Int -> (g,a)) -> (g, [a])
randomN n g f = mapAccumL (\g' x -> f g' x) g [1..n]

repIO  :: Int -> (Int -> IO a) -> IO [a]
repIO n f = sequence $ map (\x -> f x) [1..n]

randomPOI :: RandomGen g => (Int, Int) -> g -> Int -> (g, POI)
randomPOI (x,y) g uuid = let (g',rS) = getRandomState g (fromIntegral x, fromIntegral y)
                         in (g', POI rS 0 ((fromIntegral $ min x y) / 2) uuid Map.empty)

rRover :: (State -> Network Double -> Int -> Rover) -> NNVars -> (Int,Int) -> Int -> IO Rover
rRover construct vars (i,j) uuid = do
  g <- newStdGen
  let (g', rS) = getRandomState g (fromIntegral i, fromIntegral j)
  net <- create vars
  return $! construct rS net uuid
  
randomTraitor :: NNVars -> (Int, Int) -> Int -> IO Rover
randomTraitor = rRover Traitor

randomLoyalist :: NNVars -> (Int, Int) -> Int -> IO Rover
randomLoyalist = rRover Rover

randomRoverDomain :: NNVars -> (Int, Int) -> Int -> Int -> Int -> IO (RoverDomain Rover POI)
randomRoverDomain vars b@(i,j) p a t = do
  g <- newStdGen
  let l@(x,y) = (i - 1, j - 1)
      (g', rPois) = randomN p g (randomPOI l)
  rRoverL <- repIO a (randomLoyalist vars l)
  rRoverT <- repIO t (randomTraitor vars l)
  return $! RoverDomain b (rRoverL ++ rRoverT) rPois