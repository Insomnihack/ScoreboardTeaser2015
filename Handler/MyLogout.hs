module Handler.MyLogout where

import Import

getMyLogoutR :: Handler Html
getMyLogoutR = do
    deleteSession "teamName"
    deleteSession "challUser"
    deleteSession "challPwd"
    clearCreds True
    redirect HomeR
