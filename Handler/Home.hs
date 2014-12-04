{-# LANGUAGE TupleSections, OverloadedStrings #-}
module Handler.Home where

import Import
import MyAuth
import qualified Data.Text as T

getHomeR :: Handler Html
getHomeR = do
    mtid <- maybeAuthId
    case mtid of
        Nothing -> do
            ((_, loginWidget), enctype) <- liftHandlerT $ runFormPost $ renderDivs loginForm
            defaultLayout $ do
                setTitleI MsgHomeTitle
                addScript $ StaticR js_message_js
                $(widgetFile "homepage")
                $(widgetFile "messages")
        Just _ -> do
            tasks <- runDB $ selectList [TaskOpen ==. True] []
            defaultLayout $ do
                setTitleI MsgHomeTitle
                addScript $ StaticR js_pad_js
                addScript $ StaticR js_message_js
                $(widgetFile "homepageAuth")
                $(widgetFile "messages")

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


