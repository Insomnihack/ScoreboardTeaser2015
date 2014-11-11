{-# LANGUAGE ScopedTypeVariables #-}
module MyFunc where

import Import
import Data.Text as T

getScoreTeam :: TeamId -> Handler (Int, [(T.Text, T.Text)])
getScoreTeam teamId = do
                    solvedTasks <- runDB $ selectList [SolvedTeamId ==. teamId] []
                    let solvedTasksId = fmap (\(Entity _ (Solved _ sTaskId _)) -> sTaskId) solvedTasks
                    allTasks <- runDB $ selectList [TaskId <-. solvedTasksId] []
                    let score :: Int = sum $ fmap (\(Entity _ t) -> (taskValue t)) allTasks
                    let allInfos = fmap (\(Entity _ t) -> (taskName t, taskScript t)) allTasks
                    return (score, allInfos)