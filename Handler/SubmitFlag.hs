{-# LANGUAGE ScopedTypeVariables #-}
module Handler.SubmitFlag where

import Import
import qualified Data.Text as T
import qualified Data.ByteString.Base16 as HEX (encode)
import Network.Wai.Internal

postSubmitFlagR :: T.Text -> Handler Value
postSubmitFlagR taskname = do
    msg <- getMessageRender
    teamId <- requireAuthId
    (mopen :: Maybe (Entity State)) <- runDB $ selectFirst  [] []
    case mopen of
        Nothing -> do
            returnJson $ object ["status" .= (msg MsgCTFClosed)]
        Just (Entity _ open) -> do
            if (stateOpen open)
                then do
                    mtask <- runDB $ getBy $ UniqueTask taskname
                    case mtask of
                        Nothing -> do
                            returnJson $ object ["status" .= (msg MsgBadFlag)]
                        Just (Entity tid task) -> do
                            if (taskOpen task)
                                then do
                                    solved <- runDB $ getBy $ UniqueSolved teamId tid
                                    case solved of
                                        Nothing -> do
                                            request <- waiRequest
                                            bodyContent <- liftIO $ requestBody request
                                            let rflag = HEX.encode $ hash $ bodyContent
                                            let flag = taskFlag task
                                            if rflag == flag
                                                then do
                                                    time <- liftIO getCurrentTime
                                                    _ <- runDB $ insert $ Solved teamId tid time
                                                    returnJson $ object ["status" .= ("ok"::T.Text), "event" .= taskScript task]
                                                else do
                                                    returnJson $ object ["status" .= (msg MsgBadFlag)]
                                        Just _ -> do
                                            returnJson $ object ["status" .= (msg MsgAlreadySolved)]
                                else do
                                    returnJson $ object ["status" .= (msg MsgBadFlag)]
                else do
                    returnJson $ object ["status" .= (msg MsgCTFClosed)]
