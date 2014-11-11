module Handler.GetScore where

import Import
import MyFunc

getGetScoreR :: Handler Value
getGetScoreR = do
                teamId <- requireAuthId
                score <- getScoreTeam teamId
                return $ toJSON $ object ["score" .= fst score, "solved" .= map (\ (n, s) -> object["name" .= n, "event" .= s]) (snd score)]