module Handler.Rules where

import Import

getRulesR :: Handler Html
getRulesR = defaultLayout $ do
    setTitleI MsgRulesTitle
    $(widgetFile "rules")
