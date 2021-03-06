{-# LANGUAGE OverloadedStrings #-}
module Reporting.Exit.Deps
  ( Exit(..)
  , toReport
  )
  where


import qualified Elm.Constraint as Con
import qualified Elm.Package as Pkg
import qualified Elm.Version as V
import Reporting.Doc ((<>))
import qualified Reporting.Doc as D
import qualified Reporting.Exit.Help as Help



-- EXITS


data Exit
  = CorruptVersionCache FilePath Pkg.Name
  | PackageNotFound Pkg.Name [Pkg.Name]
  -- verify
  | PkgBadElm Con.Constraint
  | AppBadElm V.Version
  | AppMissingTrans [(Pkg.Name, V.Version)]
  | BadDeps
  | BuildFailure FilePath Pkg.Name V.Version



-- TO DOC


toReport :: Exit -> Help.Report
toReport exit =
  case exit of
    CorruptVersionCache elmHome pkg ->
      Help.report "CORRUPT CACHE" Nothing
        ( "I ran into an unknown package while exploring dependencies:"
        )
        [ D.indent 4 $ D.dullyellow $ D.fromUtf8 $ Pkg.toString pkg
        , D.reflow $
            "This suggests that your " ++ elmHome ++ " directory has been corrupted.\
            \ Maybe some program is messing with it? It is just cached files,\
            \ so you can delete it and see if that fixes the issue."
        ]

    PackageNotFound package suggestions ->
      Help.docReport "PACKAGE NOT FOUND" Nothing
        ( D.fillSep
            ["I","cannot","find","a"
            ,D.red (D.fromUtf8 (Pkg.toString package))
            ,"package","on","the","package","website."
            ]
        )
        [ "Maybe you want one of these instead?"
        , D.indent 4 $ D.dullyellow $ D.vcat $ map (D.fromUtf8 . Pkg.toString) suggestions
        , "But check <https://package.elm-lang.org> to see all possibilities!"
        ]

    PkgBadElm constraint ->
      Help.report "ELM VERSION MISMATCH" (Just "elm.json")
        "Your elm.json says this package needs a version of Elm in this range:"
        [ D.indent 4 $ D.dullyellow $ D.fromUtf8 $ Con.toString constraint
        , D.fillSep
            [ "But", "you", "are", "using", "Elm"
            , D.red (D.fromUtf8 (V.toString V.compiler))
            , "right", "now."
            ]
        ]

    AppBadElm version ->
      Help.report "ELM VERSION MISMATCH" (Just "elm.json")
        "Your elm.json says this application needs a different version of Elm."
        [ D.fillSep
            [ "It", "requires"
            , D.green (D.fromUtf8 (V.toString version)) <> ","
            , "but", "you", "are", "using"
            , D.red (D.fromUtf8 (V.toString V.compiler))
            , "right", "now."
            ]
        ]

    AppMissingTrans missingDeps ->
      let
        toEntry (pkg, vsn) =
          "\"" ++ Pkg.toChars pkg ++ "\": \"" ++ V.toChars vsn ++ "\""
      in
      Help.report "MISSING DEPENDENCIES" (Just "elm.json")
        "Your elm.json is missing some \"indirect\" dependencies:"
        [ D.indent 4 $ D.dullyellow $ D.vcat $ map (D.fromChars . toEntry) missingDeps
        , D.fillSep
            ["This","usually","means","you","are","editing","elm.json","by","hand."
            ,"It","is","much","more","reliable","to","use","the"
            ,D.green "elm install","command","instead."
            ]
        ]

    BadDeps ->
      Help.report "INVALID PACKAGE DEPENDENCIES" (Just "elm.json")
        "The dependencies in your elm.json are not compatible."
        [ D.fillSep
            ["Did","you","change","them","by","hand?","Try","to","change","it","back!"
            ,"It","is","much","better","to","add","dependencies","with",D.green "elm install"
            ,"or","the","dependency","management","tool","in",D.green "elm reactor" <> "."
            ]
        , D.reflow $
            "Please ask for help on the Elm slack <http://elmlang.herokuapp.com/> if\
            \ you try those paths and still cannot figure it out!"
        ]

    BuildFailure elmHome pkg vsn ->
      Help.report "CORRUPT DEPENDENCY" Nothing
        "I ran into a problem while building the following package:"
        [ D.indent 4 $ D.red $ D.fromChars $ Pkg.toChars pkg ++ " " ++ V.toChars vsn
        , D.fillSep
            ["This","probably","means","the","downloaded","files","got","corrupted","somehow."
            ,"Try","deleting",D.dullyellow (D.fromChars elmHome),"(a","directory","for"
            ,"caching","build","artifacts)","and","see","if","that","resolves","the","issue."
            ]
        ]
