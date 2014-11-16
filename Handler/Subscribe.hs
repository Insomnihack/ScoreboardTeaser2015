module Handler.Subscribe where

import Import
import MyAuth
import qualified Yesod.Core.Handler as C
import qualified Data.Text as T

getSubscribeR :: Handler Html
getSubscribeR = do
                  ((_, newAccountWidget), enctypeAccount) <- liftHandlerT $ runFormPost $ renderDivs newAccountForm
                  ((_, myResetPasswordWidget), enctypeReset) <- liftHandlerT $ runFormPost $ renderDivs myResetPasswordForm
                  ((_, resendVerifyWidget), enctypeResend) <- liftHandlerT $ runFormPost $ renderDivs resendVerifyForm
                  defaultLayout $(widgetFile "subscribe")

postSubscribeR :: Handler Html
postSubscribeR = do
                    msgr <- C.getMessageRender
                    ((result, newAccountWidget), enctypeAccount) <- liftHandlerT $ runFormPost $ renderDivs newAccountForm
                    ((_, myResetPasswordWidget), enctypeReset) <- liftHandlerT $ runFormPost $ renderDivs myResetPasswordForm
                    ((_, resendVerifyWidget), enctypeResend) <- liftHandlerT $ runFormPost $ renderDivs resendVerifyForm
                    mdata <- case result of
                      FormFailure msg -> return $ Left msg
                      FormSuccess (NewTeamData u email country pwd pwd2) -> do
                        if pwd == pwd2
                          then do
                              key <- newVerifyKey
                              hashed <- hashPassword pwd
                              mnew <- runAccountDB $ addNewUser u email key hashed
                              case mnew of
                                Left err -> do
                                  $(logWarn) err
                                  return $ Left [msgr MsgTeamMailExist]
                                Right (Entity new _) -> do
                                  runDB $ update new [TeamCountry =. country]
                                  return $ Right $ (u, email, key)
                          else return $ Left [msgr MsgPasswordsMissmatch]
                      x -> do
                        $(logWarn) $ T.pack $ show x
                        return $ Left [msgr MsgUnknownForm]

                    case mdata of
                      Left errs -> do setMessage $ toHtml $ T.intercalate (T.pack ", ") errs
                      Right (user, email, key) -> do
                        render <- getUrlRender
                        sendVerifyEmail user email $ render $ VerifyR user key
                        -- setMessageI MsgValidationLink

                    defaultLayout $(widgetFile "subscribe")

