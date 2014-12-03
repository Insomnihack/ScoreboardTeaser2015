{-# LANGUAGE ScopedTypeVariables #-}
module MyFunc where

import Import
import Data.Text as T
import Yesod.Static
import qualified Data.Text.Lazy as TL
import qualified Data.Text.Lazy.Encoding as TL

getScoreTeam :: TeamId -> Handler (Int, [(T.Text, T.Text)])
getScoreTeam teamId = do
    solvedTasks <- runDB $ selectList [SolvedTeamId ==. teamId] []
    let solvedTasksId = fmap (\ (Entity _ s) -> (solvedTaskId s)) solvedTasks

    allTasks <- runDB $ selectList [TaskId <-. solvedTasksId] []
    return $ extractInfos 0 [] allTasks

    where
        extractInfos :: Int -> [(T.Text, T.Text)] -> [Entity Task] -> (Int, [(T.Text, T.Text)])
        extractInfos a b [] = (a, b)
        extractInfos a b ((Entity _ t):xs) = extractInfos (a+(taskValue t)) (b ++ [(taskName t, taskScript t)]) xs

computeEtag :: T.Text -> Handler T.Text
computeEtag = return . T.pack . base64md5 . TL.encodeUtf8 . TL.fromStrict


isNewResponse :: T.Text -> Handler Bool
isNewResponse response = do
    etag <- computeEtag response
    addHeader ("ETag"::T.Text) etag
    uEtag <- lookupHeader "If-None-Match"
    case uEtag of
        Nothing -> return True
        Just e  -> if decodeUtf8 e == etag
            then
                return False
            else
                return True