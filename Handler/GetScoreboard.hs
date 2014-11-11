{-# LANGUAGE ScopedTypeVariables #-}
module Handler.GetScoreboard where

import Import
import qualified Data.Text as T
import qualified Data.List as L
import qualified Data.Int as I
import Data.Tuple.Select
import Data.Time.Clock.POSIX

quicksort :: (Ord a) => [(x,a,y,z)] -> [(x,a,y,z)]
quicksort [] = []
quicksort (x@(_,scoreX,_,_):xs) =
    let smallerSorted = quicksort [(name, score, ar, t) | (name, score, ar, t) <- xs, score <= scoreX]
        biggerSorted = quicksort [(name, score, ar, t) | (name, score, ar, t) <- xs, score > scoreX]
    in  biggerSorted ++ [x] ++ smallerSorted


genScoreboardLite :: [(T.Text, Int)] -> [Entity Team] -> [Entity Task] -> [Entity Solved] -> Handler [(T.Text, Int)]
genScoreboardLite res [] _ _ = do return res
genScoreboardLite res ((Entity t team):teams) tasks solveds =
                        genScoreboardLite (res ++ [((teamLogin team),(sum solvedScores))]) teams tasks solveds
                        where solvedScores :: [Int]
                              solvedScores = foldl (\a (Entity _ solved) ->
                                                    if (solvedTeamId solved) == t
                                                      then a++[getTaskValue (solvedTaskId solved)]
                                                      else a
                                                   ) [] solveds
                              getTaskValue :: Key Task -> Int
                              getTaskValue stid = (
                                                    \task -> case task of
                                                      Nothing -> 0
                                                      Just (Entity _ tval) -> (taskValue tval)
                                                  ) $ L.find (\(Entity t2 _) -> t2 == stid) tasks

genScoreboard ::  [(T.Text, Int, [(T.Text, Int, UTCTime)], UTCTime)] ->
                    [Entity Team] ->
                      [Entity Task] ->
                        [Entity Solved] ->
                          [(T.Text, Int, [(T.Text, Int, UTCTime)], UTCTime)]
genScoreboard res [] _ _ = quicksort res
genScoreboard res ((Entity t team):teams) tasks solveds =
    let
        solvedScores :: [(T.Text, Int, UTCTime)]
        solvedScores =
          let
              extractSolved :: [(T.Text, Int, UTCTime)] -> Entity Solved -> [(T.Text, Int, UTCTime)]
              extractSolved sRes (Entity _ solved)
                  | (solvedTeamId solved) == t =
                      let
                          getTask :: Solved -> (T.Text, Int, UTCTime)
                          getTask s =
                              let
                                  extractVals :: Maybe (Entity Task) -> (T.Text, Int, UTCTime)
                                  extractVals mtask =
                                      case mtask of
                                          Nothing -> ("", 0, posixSecondsToUTCTime 0)
                                          Just (Entity _ task) -> (taskName task, taskValue task, solvedTimestamp s)
                                  solvedFilterTask :: Entity Task -> Bool
                                  solvedFilterTask (Entity task _) = task == (solvedTaskId s)
                              in extractVals $ L.find solvedFilterTask tasks
                      in sRes ++ [getTask solved]
                  | otherwise                  = sRes
          in foldl extractSolved [] solveds

    in genScoreboard
        (res ++
            [(
                teamLogin team,
                sum $ map sel2 solvedScores,
                solvedScores,
                maximum $ map sel3 (solvedScores ++ [("", 0, posixSecondsToUTCTime 0)])
            )]
        ) teams tasks solveds



getGetScoreboardR :: Handler Value
getGetScoreboardR =
    do
      cacheSeconds 60
      allTeams <- runDB $ selectList [TeamVerified ==. True] [Asc TeamLogin]
      allTasks <- runDB $ selectList [TaskOpen ==. True] [Asc TaskName]
      allSolved :: [Entity Solved] <- runDB $ selectList [] []

      let scoreboard = genScoreboard [] allTeams allTasks allSolved
      let sortedScoreboard = toObject (1 :: I.Int64) scoreboard
      returnJson $ object ["tasks" .= (map extractNames allTasks), "standings" .= sortedScoreboard]
      where
          extractNames :: Entity Task -> T.Text
          extractNames (Entity _ t) = taskName t

          toObject :: I.Int64 -> [(T.Text, Int, [(T.Text, Int, UTCTime)], UTCTime)] -> [Value]
          toObject _ [] = []
          toObject i (x:xs) =
              let
                  toTaskObject :: (T.Text, Int, UTCTime) -> Value
                  toTaskObject stask =
                      object[
                          (sel1 stask) .= object[
                              "points" .= sel2 stask,
                              "time" .= (round $ utcTimeToPOSIXSeconds $ sel3 stask :: Int)
                          ]
                      ]
              in [object[
                  "pos" .= i,
                  "team" .= sel1 x,
                  "score" .= sel2 x,
                  "taskStats" .= map toTaskObject (sel3 x),
                  "lastAccept" .= (round $ utcTimeToPOSIXSeconds $ sel4 x :: Int)
                  ]] ++ (toObject (i+1) xs)



