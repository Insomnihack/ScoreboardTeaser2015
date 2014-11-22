module Handler.ResetPassword where

import Import
import MyAuth
import qualified Data.Text as T

postResetPasswordR :: Handler Html
postResetPasswordR = do
    ((result, _), _) <- liftHandlerT $ runFormPost $ renderDivs myResetPasswordForm
    case result of
        FormFailure msg -> setMessage $ toHtml $ T.intercalate (T.pack ", ") msg
        FormSuccess u -> do
            mu <- runDB $ getBy (UniqueTeamEmail u)
            case mu of
                Just user ->
                    if userEmailVerified user
                        then do
                            key <- newVerifyKey
                            runAccountDB $ setNewPasswordKey user key
                            render <- getUrlRender
                            sendNewPasswordEmail (username user) (userEmail user) $ render $ NewPasswordR (username user) key
                        else setMessageI MsgTeamNotVerified
                Nothing -> setMessageI MsgTeamNotFound
        x -> do
            $(logWarn) $ T.pack $ show x
            setMessageI MsgUnknownForm
    redirect SubscribeR
