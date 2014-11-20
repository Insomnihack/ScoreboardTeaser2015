module MyAuth where

import Import
import qualified Data.Text as T
import Flags

data NewTeamData = NewTeamData {
      newTeamUsername :: Username
    , newTeamEmail :: T.Text
    , newTeamCountry :: T.Text
    , newTeamPassword1 :: T.Text
    , newTeamPassword2 :: T.Text
} deriving Show

loginForm :: (MonadHandler m,
              YesodAuthAccount db master,
              HandlerSite m ~ master)
              => AForm m LoginData
loginForm =
    LoginData
        <$> areq textField userSettings Nothing
        <*> areq passwordField pwdSettings Nothing
    where
        userSettings = FieldSettings "Team name" Nothing (Just "username") Nothing []
        pwdSettings  = FieldSettings "Password" Nothing (Just "password") Nothing []


myResetPasswordForm :: (YesodAuthAccount db master,
                        MonadHandler m,
                        HandlerSite m ~ master)
                        => AForm m Username
myResetPasswordForm = areq textField userSettings Nothing
    where userSettings = FieldSettings "Email" Nothing Nothing (Just "resetEmail") []


myNewPasswordForm :: (YesodAuth master,
                      RenderMessage master FormMessage,
                      MonadHandler m,
                      HandlerSite m ~ master)
                      => Username
                          -> T.Text -- ^ key
                          -> AForm m NewPasswordData
myNewPasswordForm u k =
    NewPasswordData
        <$> areq hiddenField "" (Just u)
        <*> areq hiddenField "" (Just k)
        <*> areq passwordField pwdSettings1 Nothing
        <*> areq passwordField pwdSettings2 Nothing
    where
        pwdSettings1 = FieldSettings "Password" Nothing Nothing Nothing []
        pwdSettings2 = FieldSettings "Confirm password" Nothing Nothing Nothing []

newAccountForm :: (YesodAuthAccount db master,
                   MonadHandler Handler,
                   HandlerSite Handler ~ master)
                   => AForm Handler NewTeamData
newAccountForm =
    NewTeamData
        <$> areq textField userSettings Nothing
        <*> areq emailField emailSettings Nothing
        <*> areq (selectFieldList countries) countrySettings Nothing
        <*> areq passwordField pwdSettings1 Nothing
        <*> areq passwordField pwdSettings2 Nothing
    where
        userSettings  = FieldSettings "Team Name" Nothing Nothing Nothing []
        emailSettings = FieldSettings "Email" Nothing Nothing Nothing []
        countrySettings = FieldSettings "Country" Nothing Nothing Nothing []
        pwdSettings1  = FieldSettings "Password" Nothing Nothing Nothing []
        pwdSettings2  = FieldSettings "Confirm password" Nothing Nothing Nothing []


resendVerifyForm :: (YesodAuthAccount db master,
                     MonadHandler m,
                     HandlerSite m ~ master)
                     => AForm m Username
resendVerifyForm = areq textField userSettings (Just "")
    where userSettings = FieldSettings "Email" Nothing Nothing (Just "resendEmail") []