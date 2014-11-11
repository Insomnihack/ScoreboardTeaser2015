module Handler.ResendVerify where

import Import
import MyAuth
import qualified Data.Text as T

postResendVerifyR :: Handler Html
postResendVerifyR = do
                      ((result, _), _) <- liftHandlerT $ runFormPost $ renderDivs resendVerifyForm
                      case result of
                        FormFailure msg -> do setMessage $ toHtml $ T.concat msg
                        FormSuccess u -> do
                                        mu <- runDB $ getBy (UniqueTeamLogin u)
                                        case mu of
                                          Just user -> do
                                            if userEmailVerified user
                                              then do
                                                setMessageI MsgAlreadyVerified
                                                else do
                                                  key <- newVerifyKey
                                                  render <- getUrlRender
                                                  runAccountDB $ setVerifyKey user key
                                                  sendVerifyEmail (username user) (userEmail user) $ render $ VerifyR (username user) key
                                                  -- setMessageI MsgValidationLink
                                          Nothing -> do
                                            setMessageI MsgTeamNotFound
                        x -> do
                          $(logWarn) $ T.pack $ show x
                          setMessageI MsgUnknownForm
                      redirect SubscribeR
