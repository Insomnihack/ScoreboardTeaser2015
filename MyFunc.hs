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
                    let solvedTasksId = fmap (\(Entity _ (Solved _ sTaskId _)) -> sTaskId) solvedTasks
                    allTasks <- runDB $ selectList [TaskId <-. solvedTasksId] []
                    let score :: Int = sum $ fmap (\(Entity _ t) -> (taskValue t)) allTasks
                    let allInfos = fmap (\(Entity _ t) -> (taskName t, taskScript t)) allTasks
                    return (score, allInfos)

computeEtag :: T.Text -> Handler T.Text
computeEtag = return . T.pack . base64md5 . TL.encodeUtf8 . TL.fromStrict


isNewResponse :: T.Text -> Handler Bool
isNewResponse response = do
    etag <- computeEtag response
    addHeader ("ETag"::T.Text) etag
    uEtag <- lookupHeader "If-None-Match"
    case uEtag of
        Nothing -> return True
        Just e -> do
            if decodeUtf8 e == etag
                then
                    return False
                else
                    return True