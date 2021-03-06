{-# LANGUAGE ScopedTypeVariables #-}
module Handler.GetScoreboard where

import Import
import qualified Data.Text as T
import qualified Data.List as L
import qualified Data.Int as I
import MyFunc
import Data.Tuple.Select
import Data.Time.Clock.POSIX

quicksort :: [(x,z,Int,y,UTCTime)] -> [(x,z,Int,y,UTCTime)]
quicksort [] = []
quicksort (x@(_,_,scoreX,_,time):xs) =
    let smallerSorted = quicksort [(name, c, score, ar, t) | (name, c, score, ar, t) <- xs, if score == scoreX then t > time else score < scoreX]
        biggerSorted = quicksort [(name, c, score, ar, t) | (name, c, score, ar, t) <- xs, if score == scoreX then t <= time else score > scoreX]
    in  biggerSorted ++ [x] ++ smallerSorted

genScoreboard ::  [(T.Text, T.Text, Int, [(T.Text, Int, UTCTime)], UTCTime)] ->
                    [Entity Team] ->
                      [Entity Task] ->
                        [Entity Solved] ->
                          [(T.Text, T.Text, Int, [(T.Text, Int, UTCTime)], UTCTime)]
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
                  | otherwise = sRes
          in foldl extractSolved [] solveds
    in genScoreboard
        (res ++
            [(
                teamLogin team,
                teamCountry team,
                sum $ map sel2 solvedScores,
                solvedScores,
                maximum $ map sel3 (solvedScores ++ [("", 0, posixSecondsToUTCTime 0)])
            )]
        ) teams tasks solveds



getGetScoreboardR :: Handler Value
getGetScoreboardR = do
    addHeader ("Access-Control-Allow-Origin"::T.Text) ("*"::T.Text)
    addHeader ("Access-Control-Expose-Headers"::T.Text) ("Etag"::T.Text)
    addHeader ("Server"::T.Text) ("Teaser INSOMNI'HACK"::T.Text)
    cacheSeconds 1
    allTeams <- runDB $ selectList [TeamVerified ==. True] [Desc TeamLogin]
    allTasks <- runDB $ selectList [TaskOpen ==. True] [Asc TaskName]
    allSolved :: [Entity Solved] <- runDB $ selectList [] []

    let scoreboard = genScoreboard [] allTeams allTasks allSolved
    let sortedScoreboard = toObject (1 :: I.Int64) scoreboard
    let final = object ["tasks" .= (map extractNames allTasks), "standings" .= sortedScoreboard]
    modified <- isNewResponse $ T.pack $ show final
    if modified
        then
            returnJson final
        else
            sendResponseStatus status304 ("Not MofoDified" ::T.Text)
    where
        extractNames :: Entity Task -> T.Text
        extractNames (Entity _ t) = taskName t

        toObject :: I.Int64 -> [(T.Text, T.Text, Int, [(T.Text, Int, UTCTime)], UTCTime)] -> [Value]
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
            in
              if (sel3 x) > 0 then
                [object[
                      "pos" .= i,
                      "team" .= sel1 x,
                      "country" .= sel2 x,
                      "score" .= sel3 x,
                      "taskStats" .= map toTaskObject (sel4 x),
                      "lastAccept" .= (round $ utcTimeToPOSIXSeconds $ sel5 x :: Int)]]
                  ++ (toObject (i+1) xs)
              else
                (toObject (i+1) xs)



