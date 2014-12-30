{-# LANGUAGE ScopedTypeVariables #-}
module Handler.GetTasks where

import Import
import qualified Data.Text as T (Text, pack)
import MyFunc

getGetTasksR :: Handler Value
getGetTasksR = do
    tasks <- runDB $ selectList [TaskOpen ==. True] []
    let final = map extractValues tasks
    modified <- isNewResponse $ T.pack $ show final
    addHeader ("Server"::T.Text) ("Teaser INS2K15"::T.Text)
    if modified
        then
            returnJson final
        else
            sendResponseStatus status304 ("Not Modified" ::T.Text)
        where
            extractValues (Entity _ task) =
                object ["name" .= (taskName task),
                        "youtube" .= (taskYoutube task),
                        "description" .= (taskDescription task),
                        "type" .= (taskType task),
                        "points" .= (taskValue task),
                        "author" .= (taskAuthor task)]

