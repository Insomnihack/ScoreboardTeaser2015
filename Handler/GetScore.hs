module Handler.GetScore where

import Import
import MyFunc
import qualified Data.Text as T (Text, pack)

getGetScoreR :: Handler Value
getGetScoreR = do
    teamId <- requireAuthId
    mTeamName <- lookupSession "teamName"
    teamName <- case mTeamName of
        Nothing -> do
            $(logWarn) ("Logged without Team Name" ::T.Text)
            _ <- redirect MyLogoutR
            return ""
        Just t -> return t
    mChallUser <- lookupSession "challUser"
    challUser <- case mChallUser of
        Nothing -> do
            $(logWarn) ("Logged without chall User" ::T.Text)
            _ <- redirect MyLogoutR
            return ""
        Just cu -> return cu
    mChallPwd <- lookupSession "challPwd"
    challPwd <- case mChallPwd of
        Nothing -> do
            $(logWarn) ("Logged without chall pwd" ::T.Text)
            _ <- redirect MyLogoutR
            return ""
        Just cp -> return cp
    score <- getScoreTeam teamId
    let final = toObject challPwd challUser teamName score
    modified <- isNewResponse $ T.pack $ show final
    if modified
        then
            returnJson final
        else
            sendResponseStatus status304 ("Not Modified" ::T.Text)
    where
        toObject :: T.Text -> T.Text -> T.Text -> (Int, [(T.Text, T.Text)]) -> Value
        toObject challPwd challUser teamName score =
            let
                extractSolved :: (T.Text, T.Text) -> Value
                extractSolved (name, event) = object["name" .= name, "event" .= event]
            in
                object[
                    "challPwd" .= challPwd,
                    "challUser" .= challUser,
                    "teamName" .= teamName,
                    "score" .= fst score,
                    "solved" .= map extractSolved (snd score)]