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
    score <- getScoreTeam teamId
    let final = toObject teamName score
    modified <- isNewResponse $ T.pack $ show final
    addHeader ("Server"::T.Text) ("Teaser INSOMNI'HACK"::T.Text)
    if modified
        then
            returnJson final
        else
            sendResponseStatus status304 ("Not Modified" ::T.Text)
    where
        toObject :: T.Text -> (Int, [(T.Text, T.Text)]) -> Value
        toObject teamName score =
            let
                extractSolved :: (T.Text, T.Text) -> Value
                extractSolved (name, event) = object["name" .= name, "event" .= event]
            in
                object[
                    "teamName" .= teamName,
                    "score" .= fst score,
                    "solved" .= map extractSolved (snd score)]