{-# OPTIONS_GHC -Wall #-}
module Elm.PerUserCache
  ( getPackageRoot
  , getReplRoot
  , getElmHome
  )
  where

import qualified System.Directory as Dir
import qualified System.Environment as Env
import System.FilePath ((</>))

import qualified Elm.Version as V



-- ROOTS


getPackageRoot :: IO FilePath
getPackageRoot =
  getRoot "package"


getReplRoot :: IO FilePath
getReplRoot =
  getRoot "repl"


getRoot :: FilePath -> IO FilePath
getRoot projectName =
  do  home <- getElmHome
      let root = home </> version </> projectName
      Dir.createDirectoryIfMissing True root
      return root


version :: FilePath
version =
  V.toChars V.compiler


getElmHome :: IO FilePath
getElmHome =
  do  maybeHome <- Env.lookupEnv "ELM_HOME"
      maybe (Dir.getAppUserDataDirectory "elm") return maybeHome
