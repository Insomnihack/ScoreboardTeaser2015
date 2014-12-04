module Handler.Scoreboard where

import Import

getScoreboardR :: Handler Html
getScoreboardR = defaultLayout $ do
    setTitleI MsgScoreboardTitle
    addScript $ StaticR js_scoreboard_js
    $(widgetFile "scoreboard")
