module Handler.Subscribe where

import Import
import MyAuth
import qualified Data.Text as T

renderForm :: (RenderMessage (HandlerSite m) FormMessage, MonadHandler m) =>
              AForm (HandlerT (HandlerSite m) IO) a
              -> m ((FormResult a,
                     WidgetT (HandlerSite m) IO ()),
                    Enctype)
renderForm = liftHandlerT . runFormPost . renderDivs

getSubscribeR :: Handler Html
getSubscribeR = do
    ((_, newAccountWidget), enctypeAccount)    <- renderForm newAccountForm
    ((_, myResetPasswordWidget), enctypeReset) <- renderForm myResetPasswordForm
    ((_, resendVerifyWidget), enctypeResend)   <- renderForm resendVerifyForm
    defaultLayout $(widgetFile "subscribe")

postSubscribeR :: Handler Html
postSubscribeR = do
    ((result, newAccountWidget), enctypeAccount) <- renderForm newAccountForm
    ((_, myResetPasswordWidget), enctypeReset)   <- renderForm myResetPasswordForm
    ((_, resendVerifyWidget), enctypeResend)     <- renderForm resendVerifyForm
    case result of
        FormFailure msg -> setMessage $ toHtml $ T.intercalate (T.pack ", ") msg
        FormSuccess (NewTeamData team email country pwd pwd2) ->
            if pwd /= pwd2
                then setMessageI MsgPasswordsMissmatch
                else do
                    key     <- newVerifyKey
                    hashed  <- hashPassword pwd
                    mnew    <- runAccountDB $ addNewUser team email key hashed
                    case mnew of
                        Left err -> do
                            $(logWarn) err
                            setMessageI MsgTeamMailExist
                        Right (Entity new _) -> do
                            runDB $ update new [TeamCountry =. country]
                            render <- getUrlRender
                            sendVerifyEmail team email $ render $ VerifyR team key
        x -> do
            $(logWarn) $ T.pack $ show x
            setMessageI MsgUnknownForm

    defaultLayout $(widgetFile "subscribe")
