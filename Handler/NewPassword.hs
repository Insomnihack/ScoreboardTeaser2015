module Handler.NewPassword where

import Import
import MyAuth
import qualified Data.Text as T

getNewPasswordR :: Username -> T.Text -> Handler Html
getNewPasswordR uname k = do
    muser <- runAccountDB $ loadUser uname
    case muser of
        Nothing -> do
            setMessageI MsgInvalidUserKey
            redirect SubscribeR
        Just user -> do
            if userResetPwdKey user /= "" && userResetPwdKey user == k
                then do
                    ((_, myNewPasswordWidget), enctype) <- liftHandlerT $ runFormPost $ renderDivs $ myNewPasswordForm uname k
                    defaultLayout $(widgetFile "newPassword")
                else do
                    setMessageI MsgInvalidUserKey
                    redirect SubscribeR