module Handler.GetMessages where

import Import
import MyFunc
import Data.Time.Clock.POSIX
import qualified Data.Text as T (Text, pack)

getGetMessagesR :: Handler Value
getGetMessagesR =
    do
        addHeader ("Access-Control-Allow-Origin"::T.Text) ("*"::T.Text)
        addHeader ("Access-Control-Expose-Headers"::T.Text) ("Etag"::T.Text)
        cacheSeconds 30
        allMessages <- runDB $ selectList [] [Desc MessageTimestamp]
        let final = toObject allMessages
        modified <- isNewResponse $ T.pack $ show final
        addHeader ("Server"::T.Text) ("Teaser INSOMNI'HACK"::T.Text)
        if modified
            then
                returnJson final
            else
                sendResponseStatus status304 ("Not Modified" ::T.Text)
        where
            toObject :: [Entity Message] -> [Value]
            toObject [] = []
            toObject ((Entity _ msg):xs) =
                [object [
                    "time" .= (round $ utcTimeToPOSIXSeconds $ messageTimestamp msg :: Int),
                    "script" .= (messageScript msg),
                    "msg" .= (messageMessage msg),
                    "title" .= (messageTitle msg)]]
                ++ (toObject xs)

