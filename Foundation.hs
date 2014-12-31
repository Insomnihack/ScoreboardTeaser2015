{-# LANGUAGE FlexibleInstances #-}
module Foundation where

import Prelude
import Yesod
import Yesod.Static
import Yesod.Auth
import Yesod.Auth.Account
import Yesod.Default.Config
import Network.Mail.Mime
import Network.Mail.Mime.SES
import Network.Wai.Internal
import Network.HTTP.Client.Conduit (Manager, HasHttpManager (getHttpManager))
import qualified Settings
import Settings.Development (development)
import qualified Database.Persist
import Database.Persist.Sql (SqlBackend)
import Settings.StaticFiles
import Settings (widgetFile, Extra (..))
import Model
import Database.Persist.Sql (toSqlKey)
import qualified Data.Text as T
import qualified Data.Int as I
import Text.Hamlet (hamletFile)
import Text.Blaze.Html.Renderer.String
import Data.Text.Encoding (encodeUtf8, decodeUtf8)
import qualified Data.ByteString.Lazy.UTF8 as LU
import Yesod.Core.Types (Logger)

-- | The site argument for your application. This can be a good place to
-- keep settings and values requiring initialization before your application
-- starts running, such as database connections. Every handler will have
-- access to the data present here.
data App = App
    { settings :: AppConfig DefaultEnv Extra
    , getStatic :: Static -- ^ Settings for static file serving.
    , connPool :: Database.Persist.PersistConfigPool Settings.PersistConf -- ^ Database connection pool.
    , httpManager :: Manager
    , persistConfig :: Settings.PersistConf
    , appLogger :: Logger
    }

instance HasHttpManager App where
    getHttpManager = httpManager

instance PersistUserCredentials Team where
    userUsernameF = TeamLogin
    userPasswordHashF = TeamPassword
    userEmailF = TeamEmail
    userEmailVerifiedF = TeamVerified
    userEmailVerifyKeyF = TeamVerkey
    userResetPwdKeyF = TeamResetkey
    uniqueUsername = UniqueTeamLogin

    userCreate name email key pwd = Team name pwd email key False "" "" "" ""

-- Set up i18n messages. See the message folder.
mkMessage "App" "messages" "en"

-- This is where we define all of the routes in our application. For a full
-- explanation of the syntax, please see:
-- http://www.yesodweb.com/book/routing-and-handlers
--
-- Note that this is really half the story; in Application.hs, mkYesodDispatch
-- generates the rest of the code. Please see the linked documentation for an
-- explanation for this split.
mkYesodData "App" $(parseRoutesFile "config/routes")

type Form x = Html -> MForm (HandlerT App IO) (FormResult x, Widget)


isNotAuthenticated :: HandlerT App IO AuthResult
isNotAuthenticated = do
    msg <- getMessageRender
    mu <- maybeAuthId
    return $ case mu of
        Nothing -> Authorized
        Just _ -> Unauthorized $ msg MsgAlreadyAuthenticated

isAuthenticated :: HandlerT App IO AuthResult
isAuthenticated = do
    msg <- getMessageRender
    mu <- maybeAuthId
    return $ case mu of
        Nothing -> Unauthorized $ msg MsgNotAuthenticated
        Just _ -> Authorized

-- Please see the documentation for the Yesod typeclass. There are a number
-- of settings which can be configured by overriding methods here.
instance Yesod App where
    approot = ApprootRelative

    -- Store session data on the client in encrypted cookies,
    -- default session idle timeout is 120 minutes
    makeSessionBackend _ = fmap Just $ defaultClientSessionBackend
        120    -- timeout in minutes
        "config/client_session_key.aes"

    -- Authenticated routes
    isAuthorized HomeR True               = isNotAuthenticated
    isAuthorized SubscribeR _             = isNotAuthenticated
    isAuthorized (VerifyR _ _) _          = isNotAuthenticated
    isAuthorized MyLogoutR _              = isAuthenticated
    isAuthorized ResetPasswordR _         = isNotAuthenticated
    isAuthorized (NewPasswordR _ _) _     = isNotAuthenticated
    isAuthorized SetPasswordR _           = isNotAuthenticated
    isAuthorized ResendVerifyR _          = isNotAuthenticated
    isAuthorized GetTasksR _              = isAuthenticated
    isAuthorized (SubmitFlagR _) _        = isAuthenticated
    isAuthorized GetScoreR _              = isAuthenticated
    isAuthorized GetTaskIDsR _            = isAuthenticated

    isAuthorized _ _                      = return Authorized



    errorHandler NotFound= fmap toTypedContent $ defaultLayout $ do
        setTitleI MsgTitlePageNotFound
        $(widgetFile "404")
    errorHandler (InternalError errMsg) = fmap toTypedContent $ defaultLayout $ do
        $(logWarn) $ errMsg
        setTitleI MsgTitleInternalError
        $(widgetFile "500")
    errorHandler (PermissionDenied errMsg) = do
        msg <- getMessageRender
        if errMsg == (msg MsgAlreadyAuthenticated)
            then
                redirect HomeR
            else
                fmap toTypedContent $ defaultLayout $ do
                    setTitleI MsgTitleAuthRequired
                    $(widgetFile "403")

    errorHandler other = fmap toTypedContent $ defaultLayout $ do
        $(logWarn) $ T.pack $ show other
        $(widgetFile "other")

    defaultLayout widget = do
        addHeader ("Server"::T.Text) ("Teaser INS2K15"::T.Text)
        master <- getYesod
        mmsg <- getMessage
        msg <- case mmsg of
            Nothing -> do
                return ""
            Just m -> do
                return $ renderHtml m
        currRoute <- getCurrentRoute
        maid <- maybeAuthId

        -- We break up the default layout into two components:
        -- default-layout is the contents of the body tag, and
        -- default-layout-wrapper is the entire page. Since the final
        -- value passed to hamletToRepHtml cannot be a widget, this allows
        -- you to use normal widget features in default-layout.

        pc <- widgetToPageContent $ do
            addStylesheet $ StaticR css_pure_min_css
            addStylesheet $ StaticR css_grids_responsive_min_css
            addStylesheet $ StaticR css_layout_css
            addStylesheet $ StaticR css_purealert_css
            $(widgetFile "default-layout")
        withUrlRenderer $(hamletFile "templates/default-layout-wrapper.hamlet")

    -- This is done to provide an optimization for serving static files from
    -- a separate domain. Please see the staticRoot setting in Settings.hs
    urlRenderOverride y (StaticR s) =
        Just $ uncurry (joinPath y (Settings.staticRoot $ settings y)) $ renderRoute s
    urlRenderOverride _ _ = Nothing

    -- This function creates static content files in the static folder
    -- and names them based on a hash of their content. This allows
    -- expiration dates to be set far in the future without worry of
    -- users receiving stale content.
    addStaticContent _ _ _ = return Nothing

    -- Place Javascript at bottom of the body tag so the rest of the page loads first
    jsLoader _ = BottomOfBody

    -- What messages should be logged. The following includes all messages when
    -- in development, and warnings and errors in production.
    shouldLog _ _source level =
        development || level == LevelWarn || level == LevelError

    makeLogger = return . appLogger

-- How to run database actions.
instance YesodPersist App where
    type YesodPersistBackend App = SqlBackend
    runDB = defaultRunDB persistConfig connPool
instance YesodPersistRunner App where
    getDBRunner = defaultGetDBRunner connPool

instance YesodAuth App where
    type AuthId App = TeamId
    getAuthId c = return $ Just $ toSqlKey $ (read $ T.unpack (credsIdent c) :: I.Int64)
    loginDest _ = HomeR
    logoutDest _ = HomeR
    authPlugins _ = [accountPlugin]
    authHttpManager _ = error "No manager needed"
    onLogin = return ()
    maybeAuthId = do
        session <- lookupSession credsKey
        case session of
            Nothing -> return Nothing
            Just s -> return $ Just (toSqlKey $ (read $ T.unpack s :: I.Int64))

sendMail :: T.Text -> String -> T.Text -> Handler()
sendMail subject body to = do
    h <- getYesod
    let ses = SES { sesFrom = encodeUtf8 (extraSESFrom $ appExtra $ settings h),
                    sesTo = [encodeUtf8 to],
                    sesAccessKey = encodeUtf8 (extraSESAccessKey $ appExtra $ settings h),
                    sesSecretKey = encodeUtf8 (extraSESSecretKey $ appExtra $ settings h),
                    sesRegion = (extraSESRegion $ appExtra $ settings h)
                  }
    renderSendMailSES (httpManager h) ses Mail{
        mailHeaders = [ ("Subject", subject) ],
        mailFrom = Address Nothing (extraSESFrom $ appExtra $ settings h),
        mailTo = [Address Nothing to],
        mailCc = [],
        mailBcc = [],
        mailParts = return
        [ Part "text/plain" None Nothing [] $ LU.fromString $ body]
    }

getHostname :: Handler T.Text
getHostname = do
    h <- getYesod
    headers <- waiRequest
    hostname <- case (requestHeaderHost headers) of
        Just host -> return $ decodeUtf8 host
        Nothing -> return $ extraDefaultHostname $ appExtra $ settings h
    let hhostname = if extraTLS $ appExtra $ settings h
                        then
                            T.concat ["https://", hostname]
                            else
                                T.concat ["http://", hostname]
    return hhostname

instance AccountSendEmail App where
    sendVerifyEmail uname email url = do
        msg <- getMessageRender
        hostname <- getHostname
        let completeUrl = T.concat [hostname, url]
        let content = unlines [ "Hello and welcome to Insomni'hack CTF teaser.",
                                "",
                                "You have registered a team for the Insomni'hack teaser 2015.",
                                "",
                                "You team details :",
                                "Team name : " ++ T.unpack uname,
                                "Email : " ++ T.unpack email,
                                "",
                                "You MUST confirm the registration by clicking the link below:",
                                T.unpack completeUrl,
                                "",
                                "",
                                "=======",
                                "Infos",
                                "=======",
                                "",
                                "The CTF will run from Jan. 10, 2015, 9 a.m. to Jan. 11, 2015, 9 p.m. UTC",
                                "You can check your timezone here :",
                                "http://www.timeanddate.com/worldclock/converter.html?year=2015&month=1&day=10&hour=9&min=0&sec=0&p1=0&p2=270",
                                "",
                                "Please check the rules on the main site here :",
                                "https://teaser.insomnihack.ch/rules",
                                "",
                                "We hope you'll enjoy the game.",
                                "",
                                "Good luck"
                                ]
        let subj = msg MsgSubjectMailVerify
        sendMail subj content email
        setMessageI MsgValidationLink
    sendNewPasswordEmail uname email url = do
        msg <- getMessageRender
        hostname <- getHostname
        let completeUrl = T.concat [hostname, url]
        let content = unlines [ "Hello " ++ T.unpack uname ++ ",",
                                "Please go to the URL below to reset your password.",
                                "",
                                T.unpack completeUrl
                                ]
        let subj = msg MsgSubjectMailReset
        sendMail subj content email
        setMessageI MsgResetLink

instance YesodAuthAccount (AccountPersistDB App Team) App where
    runAccountDB = runAccountPersistDB

-- This instance is required to use forms. You can modify renderMessage to
-- achieve customized and internationalized form validation messages.
instance RenderMessage App FormMessage where
    renderMessage _ _ = defaultFormMessage

-- | Get the 'Extra' value, used to hold data from the settings.yml file.
getExtra :: Handler Extra
getExtra = fmap (appExtra . settings) getYesod

-- Note: previous versions of the scaffolding included a deliver function to
-- send emails. Unfortunately, there are too many different options for us to
-- give a reasonable default. Instead, the information is available on the
-- wiki:
--
-- https://github.com/yesodweb/yesod/wiki/Sending-email