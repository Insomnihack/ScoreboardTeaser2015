module Handler.Verify where

import Import
import qualified Data.Text as T
import MyFunc

getVerifyR :: Username -> T.Text -> Handler Html
getVerifyR uname k = do
    muser <- runAccountDB $ loadUser uname
    case muser of
        Nothing -> do
            setMessageI MsgInvalidUserKey
            redirect SubscribeR
        Just user@(Entity u _) ->
            if userEmailVerified user
                then do
                    setMessageI MsgAlreadyVerified
                    redirect HomeR
                else if userEmailVerifyKey user /= k
                    then do
                        setMessageI MsgInvalidUserKey
                        redirect SubscribeR
                    else do
                        runAccountDB $ verifyAccount user
                        randomName <- lift $ genString 6
                        randomPass <- lift $ genString 10
                        let userChall = T.append ("user"::T.Text) randomName
                        let userPwd = randomPass
                        runDB $ update u [TeamChalluser =. userChall, TeamChallpwd =. userPwd ]
                        setMessageI MsgWelcomeRegistered
                        redirect HomeR