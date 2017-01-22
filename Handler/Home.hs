{-# LANGUAGE TupleSections, OverloadedStrings #-}
module Handler.Home where

import Import
import MyAuth
import qualified Data.Text as T
import qualified Data.Text.Encoding as E

getHomeR :: Handler Html
getHomeR = do
    mtid <- maybeAuthId
    case mtid of
        Nothing -> do
            ((_, loginWidget), enctype) <- liftHandlerT $ runFormPost $ renderDivs loginForm
            defaultLayout $ do
                setTitleI MsgHomeTitle
                $(widgetFile "homepage")
        Just _ -> do
            tasks <- runDB $ selectList [TaskOpen ==. True] [Asc TaskName]
            mTeamName <- lookupSession "teamName"
            teamName <- case mTeamName of
                Nothing -> return ""
                Just t -> return t
            mIp <- lookupHeader "X-Forwarded-For"
            ip <- case mIp of
                Nothing -> return ""
                Just ip -> return ip
            $(logWarn) $ T.concat [("teamName : "::T.Text), teamName, (", ip : "::T.Text), E.decodeUtf8 ip]

            defaultLayout $ do
                setTitleI MsgHomeTitle
                addScript $ StaticR js_pad_js
                addScript $ StaticR js_message_js
                $(widgetFile "homepageAuth")

postHomeR :: Handler Html
postHomeR = do
    ((result, _), _) <- liftHandlerT $ runFormPost $ renderDivs loginForm
    case result of
        FormFailure msg -> setMessage $ toHtml $ T.intercalate (T.pack ", ") msg
        FormSuccess (LoginData uname pwd) -> do
            mu <- runAccountDB $ loadUser uname
            case mu of
                Nothing -> setMessageI MsgBadLoginPassword
                Just team@(Entity tid t) ->
                    if not (verifyPassword pwd (userPasswordHash team))
                        then setMessageI MsgBadLoginPassword
                        else
                            if not (userEmailVerified team)
                                then setMessageI MsgNeedValidation
                                else do
                                    setSession "teamName" (teamLogin t)
                                    setSession "challUser" (teamChalluser t)
                                    setSession "challPwd" (teamChallpwd t)
                                    setCreds True $ Creds "ctf" (toPathPiece tid) []
        x -> do
            $(logWarn) $ T.pack $ show x
            setMessageI MsgUnknownForm
    redirect HomeR


