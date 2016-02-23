import System.Posix.Files (fileExist, getSymbolicLinkStatus, isSymbolicLink, readSymbolicLink, createSymbolicLink)
import System.Directory (getHomeDirectory, getCurrentDirectory)
import Control.Monad (when)
import Control.Monad.Loops (andM)
import qualified Text.ParserCombinators.Parsec as Parsec


-- path expansion

data Context = Context
  { homeDirectory :: String
  , currentDirectory :: String
  }

expandHome :: FilePath -> FilePath -> FilePath
expandHome home ('~':'/':xs) = home ++ '/':xs
expandHome home path = path

expandCurrent :: FilePath -> FilePath -> FilePath
expandCurrent current ('/':xs) = '/':xs
expandCurrent current path = current ++ '/':path

expandPath :: Context -> FilePath -> FilePath
expandPath context path = expandCurrent (currentDirectory context) $ expandHome (homeDirectory context) $ path


-- link management

data Link = Link
  { fromPath :: String
  , toPath :: String
  }

instance Show Link where
  show link = (fromPath link) ++ " -> " ++ (toPath link)

testLink :: (FilePath -> FilePath) -> Link -> IO Bool
testLink qualify link = andM
  [ fileExist $ qualified fromPath
  , fmap isSymbolicLink . getSymbolicLinkStatus $ qualified fromPath
  , fmap (== qualified toPath) . readSymbolicLink $ qualified fromPath
  ]
  where qualified path = qualify $ path link

ensureLink :: (FilePath -> FilePath) -> Link -> IO ()
ensureLink qualify link = do
  putStrLn $ show link
  x <- testLink qualify link
  when (not x) $ createSymbolicLink (qualified toPath) (qualified fromPath)
  where qualified path = qualify $ path link


-- config file parsing

pathParser :: Parsec.Parser String
pathParser = Parsec.many (Parsec.alphaNum Parsec.<|> (Parsec.oneOf ['/','~','.'])) >>= return
  Parsec.<?> "path"

linkParser :: Parsec.Parser Link
linkParser = do
  to <- pathParser
  Parsec.string ": "
  from <- pathParser
  Parsec.char '\n'
  return Link {fromPath = from, toPath = to}
  Parsec.<?> "link"

linksParser :: Parsec.Parser [Link]
linksParser = do
  links <- Parsec.many linkParser
  Parsec.eof
  return links
  Parsec.<?> "links"


-- utility functions

unwrap :: (Show a) => Either a b -> IO b
unwrap = either (error . show) (return . id)


-- main program body

parseLinksFile = Parsec.parseFromFile linksParser "links" >>= unwrap

buildContext :: IO Context
buildContext = do
  home <- getHomeDirectory
  current <- getCurrentDirectory
  return Context {homeDirectory = home, currentDirectory = current}

main = do
  links <- parseLinksFile
  context <- buildContext
  let qualify = expandPath context
  mapM (ensureLink qualify) links
