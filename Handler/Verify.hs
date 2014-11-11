module Handler.Verify where

import Import
import qualified Data.Text as T

getVerifyR :: Username -> T.Text -> Handler Html
getVerifyR uname k = do
                          muser <- runAccountDB $ loadUser uname
                          case muser of
                            Nothing -> do setMessageI MsgInvalidUserKey
                                          redirect SubscribeR
                            Just user -> do
                                          if userEmailVerified user
                                            then do
                                              setMessageI MsgAlreadyVerified
                                              redirect HomeR
                                            else if userEmailVerifyKey user == k
                                              then do
                                                runAccountDB $ verifyAccount user
                                                setMessageI MsgWelcomeRegistered
                                                redirect HomeR
                                              else do
                                              setMessageI MsgInvalidUserKey
                                              redirect SubscribeR
