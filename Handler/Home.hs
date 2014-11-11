{-# LANGUAGE TupleSections, OverloadedStrings #-}
module Handler.Home where

import Import
import MyAuth
import MyFunc
import qualified Data.Text as T
import qualified Data.List as L
-- This is a handler function for the GET request method on the HomeR
-- resource pattern. All of your resource patterns are defined in
-- config/routes
--
-- The majority of the code you will write in Yesod lives in these handler
-- functions. You can spread them across multiple files if you are so
-- inclined, or create a single monolithic file.

getHomeR :: Handler Html
getHomeR = do
    mtid <- maybeAuthId
    case mtid of
        Nothing -> do
            ((_, loginWidget), enctype) <- liftHandlerT $ runFormPost $ renderDivs loginForm
            defaultLayout $(widgetFile "homepage")
        Just tid -> do
            mTeamName <- lookupSession "teamName"
            teamName <- case mTeamName of
                          Nothing -> do
                            $(logWarn) ("Logged without Team Name" ::T.Text)
                            _ <- redirect MyLogoutR
                            return ""
                          Just t -> return t
            solvedTasks <- getScoreTeam tid
            let isSolved task = (\ (n,_) -> n == (taskName task))
            tasks <- runDB $ selectList [TaskOpen ==. True] []
            defaultLayout $ do
                addScript $ StaticR js_pad_js
                $(widgetFile "homepageAuth")

postHomeR :: Handler Html
postHomeR = do
              msgr <- getMessageRender
              ((result, _), _) <- liftHandlerT $ runFormPost $ renderDivs loginForm
              muser <- case result of
                FormFailure msg -> return $ Left msg
                FormSuccess (LoginData uname pwd) -> do
                  mu <- runAccountDB $ loadUser uname
                  case mu of
                    Nothing -> return $ Left [msgr MsgBadLoginPassword]
                    Just u -> return $
                      if verifyPassword pwd (userPasswordHash u)
                                then Right u
                                else Left [msgr MsgBadLoginPassword]
                x -> do
                        $(logWarn) $ T.pack $ show x
                        return $ Left [msgr MsgUnknownForm]

              case muser of
                Left errs -> do
                  setMessage $ toHtml $ T.concat errs
                Right team@(Entity tid t) -> if userEmailVerified team
                            then do
                              setSession "teamName" (teamLogin t)
                              setCreds True $ Creds "ctf" (toPathPiece tid) []
                            else do
                              setMessageI MsgNeedValidation
              redirect HomeR


