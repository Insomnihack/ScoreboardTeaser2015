module Handler.MyLogout where

import Import

getMyLogoutR :: Handler Html
getMyLogoutR = do
              deleteSession "teamName"
              clearCreds True
              redirect HomeR
