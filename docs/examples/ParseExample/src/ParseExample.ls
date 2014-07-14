package
{
    import loom.Application;
    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;
    import loom2d.textures.Texture;    
    import loom2d.events.Event;
    import loom2d.events.Touch;
    import loom2d.events.TouchEvent;
    import loom2d.events.TouchPhase;

    import loom2d.text.TextField;    
    import loom2d.text.BitmapFont;
    
    import feathers.themes.MetalWorksMobileTheme;
    import feathers.controls.TextInput;
    import feathers.controls.Button;    
    import feathers.controls.Label;
    import feathers.events.FeathersEventType;

    import loom.social.Parse;



    /**
     *  Example Showcasing basic Parse REST functionality and Parse Push Note functionality
     */
    public class ParseExample extends Application
    {
        //Declare all of our controls

        var statusLabel:Label;
        var username:String;        
        var sessiontoken:String;
        var usernameInput:TextInput;        
        var passwordInput:TextInput;
        var loginButton:Button;
        var logoutButton:Button;
        var pushnoteButton:Button;

        //Import the Feathers theme we'll use for our controls
        public var theme:MetalWorksMobileTheme;

        override public function run():void
        {
            // Comment out this line to turn off automatic scaling.
            stage.scaleMode = StageScaleMode.LETTERBOX;
            /*stage.stageWidth = 640;
            stage.stageHeight = 480;*/
            
            //Initialize Feathers source assets
            TextField.registerBitmapFont(BitmapFont.load("assets/arialComplete.fnt"), "SourceSansPro");
            TextField.registerBitmapFont(BitmapFont.load("assets/arialComplete.fnt"), "SourceSansProSemibold");
            theme = new MetalWorksMobileTheme();           

            //Get REST credentials from loom.config file and pass to Parse
            var config = new JSON();
            config.loadString(Application.loomConfigJSON);
            Parse.REST_setCredentials(config.getString("parse_app_id"), config.getString("parse_rest_key"));

            //Set our onTimeout delegate. This will trigger after 10 seconds (by default) without a server response.
            Parse.REST_onTimeout = function()
            {
                statusLabel.text = "Timed out.";
            };

            
            statusLabel = new Label();
            statusLabel.text = "Please log in";
                        
            statusLabel.x = stage.stageWidth / 2-100;
            statusLabel.y = 40;
            
            stage.addChild(statusLabel);

            usernameInput = new TextInput();
            usernameInput.x = stage.stageWidth / 2-100;
            usernameInput.y = 100;            
            usernameInput.prompt = "Username";                        
            usernameInput.maxChars = 100; 
            usernameInput.isEditable = true;                                
            stage.addChild(usernameInput);
                        
            passwordInput = new TextInput();
            passwordInput.x = stage.stageWidth / 2-100;
            passwordInput.y = 150;
            passwordInput.prompt = "Password";            
            passwordInput.displayAsPassword = true; 
            passwordInput.maxChars = 100; 
            passwordInput.isEditable = true; 
            stage.addChild(passwordInput);         
           
            loginButton = new Button();
            loginButton.width = 100;
            loginButton.height = 50;
            loginButton.x = stage.stageWidth / 2;
            loginButton.y = 250;
            loginButton.label = "Login!";
            loginButton.center();
            loginButton.addEventListener(Event.TRIGGERED,loginUser);
            stage.addChild(loginButton);   

            logoutButton = new Button();
            logoutButton.width = 100;
            logoutButton.height = 50;
            logoutButton.x = stage.stageWidth / 2;
            logoutButton.y = 250;
            logoutButton.label = "Logout!";
            logoutButton.center();
            logoutButton.addEventListener(Event.TRIGGERED,logoutUser);
            logoutButton.visible = false;
            stage.addChild(logoutButton);   

            pushnoteButton = new Button();
            pushnoteButton.width = 280;
            pushnoteButton.height = 75;
            pushnoteButton.x = stage.stageWidth / 2;
            pushnoteButton.y = 185;
            pushnoteButton.label = "Send Push Notification!";
            pushnoteButton.center();
            pushnoteButton.addEventListener(Event.TRIGGERED,sendPN);
            pushnoteButton.visible = false;         
            stage.addChild(pushnoteButton);                                               
        }



        //Call the Parse tick function to increment timeout and the request queue timer.
        //If this is not called, requests will not send or time out.
        override public function onTick():void
        {            
            super.onTick();

            //tick Parse so that it can handle timeouts
            Parse.tick();
        }



        //Logs the user into a user account with the provided credentials
        public function loginUser(e:Event)
        {           
            //Ensure we don't try sending empty strings.
            if(String.isNullOrEmpty(usernameInput.text) || String.isNullOrEmpty(passwordInput.text))
            {
                return;
            }

            //Update our status label
            statusLabel.text = "Logging in...";
            

            //Fire off the Parse REST function to log the user in                          
            Parse.REST_loginWithUsername(usernameInput.text,passwordInput.text,
            function(result:String) //request success delegate
            {
                trace(result);
                
                //Create a JSON object to parse the result the server returned
                var responseJSON:JSON = new JSON();
                responseJSON.loadString(result);

                username = responseJSON.getString("username");
                statusLabel.text = username+" logged in!";
                
                sessiontoken = responseJSON.getString("sessionToken");

                //Set the user's session token in the Parse object.
                Parse.REST_SessionToken = sessiontoken;

                //If Parse Push Notes are supported on this device, we pass the username to the Installation so we can target our push notes.
                if(Parse.isActive())
                {
                    Parse.updateInstallationUserID(username);
                }

                //Change our UI to send Push Notes
                usernameInput.text = "";
                usernameInput.prompt = "Receiver's username";
                passwordInput.text = "";
                passwordInput.visible=false;
                loginButton.visible=false;
                logoutButton.visible=true;
                pushnoteButton.visible=true;

            },
            function(result:String) //request failure delegate
            {
                trace(result);
                statusLabel.text = "Login failed!";
                
            });
        }

        //Resets our stored credentials and UI
        public function logoutUser()
        {
            username = "";
            sessiontoken = "";
            usernameInput.text = "";
            usernameInput.prompt = "Username";         
            passwordInput.visible = true;
            loginButton.visible = true;
            logoutButton.visible = false;
            pushnoteButton.visible = false;

            statusLabel.text = "Logged out!";
            
        }


        //Calls a Parse Cloud Function that sends a push note to the specified user.
        public function sendPN()
        {
            if(String.isNullOrEmpty(usernameInput.text))
            {
                statusLabel.text = "Please enter a recipient username.";
                return;
            }
            statusLabel.text = "Sending Push Notification...";

            //Construct a JSON object to pass parameters to our cloud function
            
            var dataJSON = new JSON();
            dataJSON.loadString("{}");
            dataJSON.setString("recipientName",usernameInput.text);

            //Call the cloud function via Parse
            Parse.REST_callCloudFunction("sendPN",dataJSON,
            function(result:String) //Success!
            {
                usernameInput.text = "";
                statusLabel.text = "Push Notification Sent!";
            },
            function(result:String) //Failure!
            {
                statusLabel.text = "Error running cloud code";
            });
        }
    }
}