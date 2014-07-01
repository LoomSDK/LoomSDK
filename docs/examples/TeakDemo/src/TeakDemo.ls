package
{
    import loom.Application;
    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;
    import loom2d.textures.Texture;
    import loom2d.ui.SimpleLabel;
   
    import loom.social.Facebook;
    import loom.social.FacebookSessionState;
    import loom.social.FacebookErrorCode;
    import loom.social.Teak;
    import loom.HTTPRequest;

    import loom2d.events.Event;

    import feathers.themes.MetalWorksMobileTheme;
    import feathers.controls.TextInput;
    import feathers.controls.Button;
    import feathers.controls.Label;
    import feathers.events.FeathersEventType;

    import loom2d.text.TextField;    
    import loom2d.text.BitmapFont;

    public class TeakDemo extends Application
    {
        var fbAccessToken:String;
        var label:Label;
        var fbLoginButton:Button;
        var fbPublishButton:Button;
        var teakPostButton:Button;
        var theme:MetalWorksMobileTheme;
        var teakIsReady:Boolean = false;

        override public function run():void
        {
            // Comment out this line to turn off automatic scaling.
            stage.scaleMode = StageScaleMode.LETTERBOX;

            //Initialize Feathers source assets
            TextField.registerBitmapFont(BitmapFont.load("assets/arialComplete.fnt"), "SourceSansPro");
            TextField.registerBitmapFont(BitmapFont.load("assets/arialComplete.fnt"), "SourceSansProSemibold");
            theme = new MetalWorksMobileTheme();  

            // Setup feedback label first                      

            label = new Label();
            label.text = "Hello Teak!";
            label.width = stage.stageWidth*2/3;
            label.height = 100;
            label.center();
            label.x = stage.stageWidth / 2;
            label.y = stage.stageHeight / 2 - 75;
            stage.addChild(label);

            //If the device doesn't support FB natively, display an error and ignore the rest of this function.            
            if(!Facebook.isActive())
            {
                label.text = "Sorry, Facebook is not supported on this device.";
                label.center();
                Debug.print("{FACEBOOK} Sorry, Facebook is not initialised on this device. Facebook is only supported on Android and iOS.");
                return;
            }

            //Delegate a function to Facebook onSessionStatus to handle any changes in session.
            Facebook.onSessionStatus = sessionStatusChanged;

            //Delegate a handler to Teak for when its auth status changes.
            Teak.onAuthStatus = teakAuthStatusChanged;
            
            //Add our buttons
            fbLoginButton = new Button();
            fbLoginButton.label = "Log in to Facebook!";
            fbLoginButton.x = label.x = stage.stageWidth / 2;
            fbLoginButton.y = stage.stageHeight / 2;
            fbLoginButton.width = 200;
            fbLoginButton.height = 50;
            fbLoginButton.center();
            fbLoginButton.addEventListener(Event.TRIGGERED,
            function(e:Event)
            {
                //We open our session with email read permissions. This will automatically prompt the user to log in and provide permissions if necessary.
                Facebook.openSessionWithReadPermissions("email");
            });
            stage.addChild(fbLoginButton);

            fbPublishButton = new Button();
            fbPublishButton.label = "Get FB publish permissions!";
            fbPublishButton.x = label.x = stage.stageWidth / 2;
            fbPublishButton.y = stage.stageHeight / 2;
            fbPublishButton.width = 200;
            fbPublishButton.height = 50;
            fbPublishButton.center();
            fbPublishButton.visible=false;
            fbPublishButton.addEventListener(Event.TRIGGERED,
            function(e:Event)
            {
                //We request publish permissions from Facebook
                Facebook.requestNewPublishPermissions("publish_actions");
            });
            stage.addChild(fbPublishButton);

            teakPostButton = new Button();
            teakPostButton.label = "Post Achievement!";
            teakPostButton.x = label.x = stage.stageWidth / 2;
            teakPostButton.y = stage.stageHeight / 2;
            teakPostButton.width = 200;
            teakPostButton.height = 50;
            teakPostButton.center();
            teakPostButton.visible=false;
            teakPostButton.addEventListener(Event.TRIGGERED,
            function(e:Event)
            {
                //We open our session with email read permissions. This will automatically prompt the user to log in and provide permissions if necessary.
                Teak.postAchievement("teakWorks");
                label.text = "Posting achievement. Check your Facebook account.";
            });
            stage.addChild(teakPostButton);

              
            
        }

        function sessionStatusChanged(sessionState:FacebookSessionState, sessionPermissions:String, errorCode:FacebookErrorCode):void
        {           

            Debug.print("{FACEBOOK} sessionState changes to: " + sessionState.toString() + " with permissions: " + sessionPermissions);

            if(errorCode != FacebookErrorCode.NoError)
            {            
               switch(errorCode)
                {
                    case FacebookErrorCode.RetryLogin:
                        label.text = "Facebook login error. Please retry.";

                        break;
                    
                    case FacebookErrorCode.UserCancelled:                        

//User cancelled the login process, so rest states and let them try again
                        
                        label.text = "Facebook login cancelled by user.";

                        break;
                    
                    case FacebookErrorCode.ApplicationNotPermitted:                        

//Application does not have permission to access Facebook, likely on iOS.
                        label.text = "Facebook application error. Please ensure your Facebook app has the correct settings.";
                        
                        break;
                    
                    case FacebookErrorCode.Unknown:  

//Could be anything... display generic FB error dialog and let user try whatever they were doing again
                        
                        label.text = "An unknown Facebook error occurred.";
                        break;
                }
                return;   
            }


            //Note that you'll have needed to set up a test app on Facebook and placed its Application ID in your config files before it will open a session.

            if (sessionState==FacebookSessionState.Opened)
            {
                label.text = "Facebook session is open.\n";
                Debug.print("{FACEBOOK} sessionPermissions: " + sessionPermissions);
                                
                fbAccessToken = Facebook.getAccessToken();
                fbLoginButton.visible = false;
                fbPublishButton.visible=true;

                Debug.print("{FACEBOOK} access token:       " + fbAccessToken);
    
                if (String.isNullOrEmpty(fbAccessToken))
                {
                    label.text += "Error: Invalid FB Access Token.";
                    Debug.print("{FACEBOOK} Error: Invalid FB Access Token.");
                    return;
                }

                if(!Facebook.isPermissionGranted("publish_actions"))
                {
                    label.text += "We do not have publish permissions. Requesting.";
                    trace("{FACEBOOK} We do not have publish permissions. Requesting.");
                    
                }
                else
                {
                    label.text += "We have publish permissions.";
                    trace("{FACEBOOK} We have publish permissions.");
                    fbPublishButton.visible=false;
                    InitTeak();   
                }
            }

            if (sessionState==FacebookSessionState.Closed)
            {
                label.text = "Facebook session has been closed.";
                Debug.print("{FACEBOOK} Session closed.");
            }

        }

        function InitTeak()
        {
            
            if(Teak.isActive())
            {
                label.text += "\nPassing access token to Teak.";
                trace("{TEAK} Facebook access token passed to Teak.");
                Teak.setAccessToken(fbAccessToken);
                
                trace("{TEAK} Access status is "+Teak.getStatus());                
                
            }
            else
            {
               label.text += "\nerror: Teak not initialized.";
               trace("{TEAK} Teak not initialized."); 
            }
        }

        function teakAuthStatusChanged()
        {
            trace("{TEAK} Auth Status has changed.");
            trace("{TEAK} Access status is now "+Teak.getStatus());
            if(Teak.getStatus() == 2)
                {
                    teakIsReady = true;
                    teakPostButton.visible=true;
                }
            else
                teakIsReady = false;

            trace("{TEAK} Ready: "+teakIsReady);
            label.text+="\nTeak ready: "+teakIsReady;
        }
    }
}