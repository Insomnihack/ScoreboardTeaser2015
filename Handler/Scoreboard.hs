module Handler.Scoreboard where

import Import

getScoreboardR :: Handler Html
getScoreboardR = defaultLayout $ do
    addScript $ StaticR js_scoreboard_js
    $(widgetFile "scoreboard")
