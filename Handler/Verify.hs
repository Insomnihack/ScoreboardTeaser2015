module Handler.Verify where

import Import
import System.Random
import System.IO.Unsafe
import qualified Data.Text as T

getVerifyR :: Username -> T.Text -> Handler Html
getVerifyR uname k = do
                          muser <- runAccountDB $ loadUser uname
                          case muser of
                            Nothing -> do setMessageI MsgInvalidUserKey
                                          redirect SubscribeR
                            Just user@(Entity u _) -> do
                                          if userEmailVerified user
                                            then do
                                              setMessageI MsgAlreadyVerified
                                              redirect HomeR
                                            else if userEmailVerifyKey user == k
                                              then do
                                                runAccountDB $ verifyAccount user
                                                let randomStr = filter (\ x -> x `elem`(['a','b'..'z']++['0','1'..'9']++['A','B'..'Z'])) $ randomRs ('0','z') $ unsafePerformIO newStdGen
                                                let userChall = T.append ("user"::T.Text) $ T.pack $ take 6 $ randomStr
                                                let userPwd = T.pack $ take 10 $ drop 1337 randomStr
                                                runDB $ update u [TeamChalluser =. userChall, TeamChallpwd =. userPwd ]
                                                setMessageI MsgWelcomeRegistered
                                                redirect HomeR
                                              else do
                                              setMessageI MsgInvalidUserKey
                                              redirect SubscribeR
