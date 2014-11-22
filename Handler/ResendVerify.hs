module Handler.ResendVerify where

import Import
import MyAuth
import qualified Data.Text as T

postResendVerifyR :: Handler Html
postResendVerifyR = do
    ((result, _), _) <- liftHandlerT $ runFormPost $ renderDivs resendVerifyForm
    case result of
        FormFailure msg -> setMessage $ toHtml $ T.intercalate (T.pack ", ") msg
        FormSuccess u -> do
            mu <- runDB $ getBy (UniqueTeamEmail u)
            case mu of
                Just user ->
                    if userEmailVerified user
                        then setMessageI MsgAlreadyVerified
                        else do
                            key <- newVerifyKey
                            render <- getUrlRender
                            runAccountDB $ setVerifyKey user key
                            sendVerifyEmail (username user) (userEmail user) $ render $ VerifyR (username user) key
                Nothing -> setMessageI MsgTeamNotFound
        x -> do
            $(logWarn) $ T.pack $ show x
            setMessageI MsgUnknownForm
    redirect SubscribeR
