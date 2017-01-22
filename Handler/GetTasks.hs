{-# LANGUAGE ScopedTypeVariables #-}
module Handler.GetTasks where

import Import
import qualified Data.Text as T (Text, pack)
import MyFunc

getGetTasksR :: Handler Value
getGetTasksR = do
    tasks <- runDB $ selectList [TaskOpen ==. True] [Asc TaskName]
    let final = map extractValues tasks
    modified <- isNewResponse $ T.pack $ show final
    addHeader ("Server"::T.Text) ("Teaser INSOMNI'HACK"::T.Text)
    if modified
        then
            returnJson final
        else
            sendResponseStatus status304 ("Not Modified" ::T.Text)
        where
            extractValues (Entity _ task) =
                object ["name" .= (taskName task),
                        "special" .= (taskSpecial task),
                        "description" .= (taskDescription task),
                        "type" .= (taskType task),
                        "value" .= (taskValue task),
                        "author" .= (taskAuthor task)]

