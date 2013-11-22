package
{

    import loom.Application;
    import loom.HTTPRequest;

    import loom2d.events.Event;
    import loom2d.text.TextField;
    import loom2d.text.BitmapFont;

    import feathers.system.DeviceCapabilities;
    import feathers.events.FeathersEventType;
    import feathers.controls.PanelScreen;
    import feathers.controls.TextInput;
    import feathers.controls.Button;
    import feathers.controls.Label;

    import feathers.layout.VerticalLayout;
    import feathers.layout.AnchorLayout;
    import feathers.layout.AnchorLayoutData;
    import feathers.themes.MetalWorksMobileTheme;
    import feathers.controls.ScreenNavigator;
    import feathers.controls.ScreenNavigatorItem;
    import feathers.motion.transitions.ScreenSlidingStackTransitionManager;

    public class FeathersExample extends Application
    {
        public var theme:MetalWorksMobileTheme;
        public static var navigator:ScreenNavigator;
        public static var loginMessage:String = "";
        private var _transitionManager:ScreenSlidingStackTransitionManager;

        override public function run():void
        {

            DeviceCapabilities.screenPixelWidth = stage.nativeStageWidth;
            DeviceCapabilities.screenPixelHeight = stage.nativeStageHeight;
            DeviceCapabilities.dpi = DeviceCapabilities.screenPixelWidth / 2; // Assume a 2in wide screen.

            // Register fonts.
            TextField.registerBitmapFont(BitmapFont.load("assets/arialComplete.fnt"), "SourceSansPro");
            TextField.registerBitmapFont(BitmapFont.load("assets/arialComplete.fnt"), "SourceSansProSemibold");

            //create the theme. this class will automatically pass skins to any
            //Feathers component that is added to the stage. components do not
            //have default skins, so you must always use a theme or skin the
            //components manually. you should always create a theme immediately
            //when your app starts up to ensure that all components are
            //properly skinned.
            //see http://wiki.starling-framework.org/feathers/themes
            theme = new MetalWorksMobileTheme();

            // Initialize the ScreenNavigator...
            navigator = new ScreenNavigator();
            navigator.addScreen("login", new ScreenNavigatorItem(LoginScreen, { complete: "login" }));
            navigator.addScreen("success", new ScreenNavigatorItem(SuccessScreen, { complete: "login" }));
            navigator.addScreen("failure", new ScreenNavigatorItem(FailureScreen, { complete: "login" }));
            stage.addChild(navigator);

            // Start us on the login screen.
            navigator.showScreen("login");

            // Schmexy Transitions
            _transitionManager = new ScreenSlidingStackTransitionManager(navigator);
            _transitionManager.duration = 0.4;            
        }
    }

    public class LoginScreen extends PanelScreen
    {
        public static const SHOW_SETTINGS:String = "showSettings";

        public function LoginScreen()
        {
            addEventListener(FeathersEventType.INITIALIZE, initializeHandler);
        }

        //public var settings:TextInputSettings;        
        private var _loginButton:Button;

        private var _email:TextInput;
        private var _password:TextInput;

        protected function initializeHandler(event:Event):void
        {
            const verticalLayout:VerticalLayout = new VerticalLayout();
            verticalLayout.horizontalAlign = VerticalLayout.HORIZONTAL_ALIGN_CENTER;
            verticalLayout.verticalAlign = VerticalLayout.VERTICAL_ALIGN_TOP;
            verticalLayout.padding = 20 * dpiScale;
            verticalLayout.gap = 16 * dpiScale;
            verticalLayout.manageVisibility = true;
            layout = verticalLayout;

            _email = new TextInput();
            _email.prompt = "Email Address";
            _email.displayAsPassword = false; 
            _email.maxChars = 100; 
            _email.isEditable = true; 
            addChild(_email);

            _password = new TextInput();
            _password.prompt = "Password";
            _password.displayAsPassword = true; 
            _password.maxChars = 100; 
            _password.isEditable = true; 
            addChild(_password);

            headerProperties["title"] = "Log into\nThe Engine Company";

            _loginButton = new Button();
            _loginButton.label = "Login!";
            _loginButton.addEventListener(Event.TRIGGERED, loginButton_triggeredHandler);

            headerProperties["rightItems"] = new <DisplayObject>
            [
                _loginButton
            ];
        }

        private function onBackButton():void
        {
            dispatchEventWith(Event.COMPLETE);
        }

        // TODO: LOOM-1480
        // we need to keep the httpRequests alive so we receive 
        // them (or they may be garbage collected, see JIRA issue)
        var httpRequests = [];

        private function loginButton_triggeredHandler(event:Event):void
        {
            trace("Sending request...");

            var req = new HTTPRequest("http://www.loomsdk.com/api/v1/session");
            req.method = "POST";
            req.body = "email=" + _email.text + "&password=" + _password.text;
            req.setHeaderField("foo", "bar");

            httpRequests.push(req);

            req.onSuccess += function(v:String) { 
                
                var json = new JSON();
                json.loadString(v);
                trace(v);
    
                var code = json.getObject("meta").getInteger("code");

                if (code == 201)
                {
                    // success
                    FeathersExample.loginMessage = "Response Code: " + json.getString("response");
                    FeathersExample.navigator.showScreen("success");

                }
                else
                {
                    //error
                    FeathersExample.loginMessage = json.getObject("meta").getString("message");
                    FeathersExample.navigator.showScreen("failure");
                }

            };

            req.onFailure += function(v:String) { trace("Error:", v); };
            req.send();            
        }
    }

    public class FailureScreen extends PanelScreen
    {

        public function FailureScreen()
        {
            addEventListener(FeathersEventType.INITIALIZE, initializeHandler);
        }

        //public var settings:TextInputSettings;
        private var _backButton:Button;
        private var _message:Label;

        protected function initializeHandler(event:Event):void
        {

            _message = new Label();
            _message.text = FeathersExample.loginMessage;
            addChild(_message);

            headerProperties["title"] = "Login Failure";

            _backButton = new Button();
            _backButton.nameList.add(Button.ALTERNATE_NAME_BACK_BUTTON);
            _backButton.label = "Back";
            _backButton.addEventListener(Event.TRIGGERED, backButton_triggeredHandler);

            headerProperties["leftItems"] = new <DisplayObject>
            [
                _backButton
            ];

            backButtonHandler = onBackButton;
        }

        private function onBackButton():void
        {
            dispatchEventWith(Event.COMPLETE);
        }

        private function backButton_triggeredHandler(event:Event):void
        {
            onBackButton();
        }

    }

    public class SuccessScreen extends PanelScreen
    {

        public function SuccessScreen()
        {
            addEventListener(FeathersEventType.INITIALIZE, initializeHandler);
        }

        //public var settings:TextInputSettings;
        private var _backButton:Button;
        private var _message:Label;

        protected function initializeHandler(event:Event):void
        {

            _message = new Label();
            _message.text = FeathersExample.loginMessage;
            addChild(_message);

            headerProperties["title"] = "Login Success";

            _backButton = new Button();
            _backButton.nameList.add(Button.ALTERNATE_NAME_BACK_BUTTON);
            _backButton.label = "Back";
            _backButton.addEventListener(Event.TRIGGERED, backButton_triggeredHandler);

            headerProperties["leftItems"] = new <DisplayObject>
            [
                _backButton
            ];

            backButtonHandler = onBackButton;
        }

        private function onBackButton():void
        {
            dispatchEventWith(Event.COMPLETE);
        }

        private function backButton_triggeredHandler(event:Event):void
        {
            onBackButton();
        }

    }

}