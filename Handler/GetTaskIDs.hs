module Handler.GetTaskIDs where

import Import
import MyFunc
import qualified Data.Text as T (Text, pack)

getGetTaskIDsR :: Handler Value
getGetTaskIDsR = do
    teamId <- requireAuthId
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
    let final = toObject challPwd challUser
    modified <- isNewResponse $ T.pack $ show final
    if modified
        then
            returnJson final
        else
            sendResponseStatus status304 ("Not Modified" ::T.Text)
    where
        toObject :: T.Text -> T.Text -> Value
        toObject challPwd challUser =
            object[
                "challPwd" .= challPwd,
                "challUser" .= challUser]