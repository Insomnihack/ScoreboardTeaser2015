module Handler.GetMessages where

import Import
import MyFunc
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
                    "time" .= (messageTimestamp msg),
                    "script" .= (messageScript msg),
                    "msg" .= (messageMessage msg),
                    "title" .= (messageTitle msg)
                ]] ++ (toObject xs)

