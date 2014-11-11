{-# LANGUAGE ScopedTypeVariables #-}
module Handler.GetTasks where

import Import

getGetTasksR :: Handler Value
getGetTasksR = do
                tasks <- runDB $ selectList [TaskOpen ==. True] []
                returnJson $ map extractValues tasks
                where
                  extractValues (Entity tid task) = object [ "id" .= tid
                                                            ,"name" .= (taskName task)
                                                            ,"description" .= (taskDescription task)
                                                            ,"type" .= (taskType task)
                                                            ,"points" .= (taskValue task)
                                                            ,"author" .= (taskAuthor task)
                                                            ]
