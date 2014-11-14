module Handler.SetPassword where

import Import
import MyAuth
import qualified Data.Text as T

postSetPasswordR :: Handler Html
postSetPasswordR = do
              ((result, _), _) <- liftHandlerT $ runFormPost $ renderDivs $ myNewPasswordForm "" ""
              case result of
                FormFailure msg -> setMessage $ toHtml $ T.intercalate (T.pack ", ") msg
                FormSuccess (NewPasswordData uname key pwd1 pwd2) -> do
                  muser <- runAccountDB $ loadUser uname
                  case muser of
                    Nothing -> do
                      setMessageI MsgInvalidUserKey
                    Just user -> do
                      if userResetPwdKey user /= "" && userResetPwdKey user == key
                        then do
                          if pwd1 == pwd2
                            then do
                              hashed <- hashPassword pwd1
                              runAccountDB $ setNewPassword user hashed
                              setMessageI MsgInvalidUserKey
                              redirect HomeR
                              else do
                                setMessageI MsgPasswordsMissmatch
                                redirect $ NewPasswordR uname key

                        else do
                          setMessageI MsgInvalidUserKey
                x -> do
                        $(logWarn) $ T.pack $ show x
                        setMessageI MsgUnknownForm
              redirect SubscribeR
