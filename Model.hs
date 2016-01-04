{-# LANGUAGE FlexibleInstances #-}
module Model where

import Yesod
import Data.Text (Text)
import Database.Persist.Quasi
import Data.Typeable (Typeable)
import Data.Time
import Data.ByteString (ByteString)
import Prelude

-- You can define all of your database entities in the entities file.
-- You can find more information on persistent and how to declare entities
-- at:
-- http://www.yesodweb.com/book/persistent/
share [mkPersist sqlSettings, mkMigrate "migrateAll"]
    $(persistFileWith lowerCaseSettings "config/models")


instance ToJSON (Entity Task) where
    toJSON (Entity _ task) = object [  "name" .= (taskName task),
                                        "special" .= (taskSpecial task),
                                        "description" .= (taskDescription task),
                                        "type" .= (taskType task),
                                        "value" .= (taskValue task),
                                        "author" .= (taskAuthor task)]