module Handler.Subscribe where

import Import
import MyAuth
import qualified Data.Text as T

getSubscribeR :: Handler Html
getSubscribeR = do
                  ((_, newAccountWidget), enctypeAccount) <- liftHandlerT $ runFormPost $ renderDivs newAccountForm
                  ((_, myResetPasswordWidget), enctypeReset) <- liftHandlerT $ runFormPost $ renderDivs myResetPasswordForm
                  ((_, resendVerifyWidget), enctypeResend) <- liftHandlerT $ runFormPost $ renderDivs resendVerifyForm
                  defaultLayout $(widgetFile "subscribe")

postSubscribeR :: Handler Html
postSubscribeR = do
                    msgr <- getMessageRender
                    ((result, newAccountWidget), enctypeAccount) <- liftHandlerT $ runFormPost $ renderDivs newAccountForm
                    ((_, myResetPasswordWidget), enctypeReset) <- liftHandlerT $ runFormPost $ renderDivs myResetPasswordForm
                    ((_, resendVerifyWidget), enctypeResend) <- liftHandlerT $ runFormPost $ renderDivs resendVerifyForm
                    mdata <- case result of
                      FormFailure msg -> return $ Left msg
                      FormSuccess (NewAccountData u email pwd pwd2) -> do
                        if pwd == pwd2
                          then do
                              key <- newVerifyKey
                              hashed <- hashPassword pwd
                              mnew <- runAccountDB $ addNewUser u email key hashed
                              case mnew of
                                Left err -> do
                                  $(logWarn) err
                                  return $ Left [msgr MsgTeamMailExist]
                                Right _ -> do return $ Right $ (u, email, key)
                          else return $ Left [msgr MsgPasswordsMissmatch]
                      x -> do
                        $(logWarn) $ T.pack $ show x
                        return $ Left [msgr MsgUnknownForm]

                    case mdata of
                      Left errs -> do setMessage $ toHtml $ T.concat errs
                      Right (user, email, key) -> do
                        render <- getUrlRender
                        sendVerifyEmail user email $ render $ VerifyR user key
                        -- setMessageI MsgValidationLink

                    defaultLayout $(widgetFile "subscribe")

