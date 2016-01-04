{-# LANGUAGE ScopedTypeVariables #-}
module Handler.SubmitFlag where

import Import
import qualified Data.Text as T
import qualified Data.ByteString.Base16 as HEX (encode)
import Network.Wai.Internal

postSubmitFlagR :: T.Text -> Handler Value
postSubmitFlagR taskname = do
    addHeader ("Server"::T.Text) ("Teaser INS2K16"::T.Text)
    msg <- getMessageRender
    teamId <- requireAuthId
    (mopen :: Maybe (Entity State)) <- runDB $ selectFirst  [] []
    case mopen of
        Nothing -> returnJson $ object ["status" .= (msg MsgCTFClosed)]
        Just (Entity _ open) ->
            if not (stateOpen open)
                then returnJson $ object ["status" .= (msg MsgCTFClosed)]
                else do
                    mtask <- runDB $ getBy $ UniqueTask taskname
                    case mtask of
                        Nothing -> returnJson $ object ["status" .= (msg MsgBadFlag)]
                        Just (Entity tid task) ->
                            if not (taskOpen task)
                                then returnJson $ object ["status" .= (msg MsgBadFlag)]
                                else do
                                    solved <- runDB $ getBy $ UniqueSolved teamId tid
                                    case solved of
                                        Just _ -> returnJson $ object ["status" .= (msg MsgAlreadySolved)]
                                        Nothing -> do
                                            request <- waiRequest
                                            bodyContent <- liftIO $ requestBody request
                                            let rflag = HEX.encode $ hash $ bodyContent
                                            let flag  = taskFlag task
                                            if rflag /= flag
                                                then returnJson $ object ["status" .= (msg MsgBadFlag)]
                                                else do
                                                    time <- liftIO getCurrentTime
                                                    _ <- runDB $ insert $ Solved teamId tid time
                                                    returnJson $ object ["status" .= ("ok"::T.Text), "event" .= taskScript task]
