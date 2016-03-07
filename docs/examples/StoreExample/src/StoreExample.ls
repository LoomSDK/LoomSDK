package
{

    import loom.Application;    
    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;   
    import loom2d.math.Point;   
    import loom2d.textures.Texture;
    import loom2d.ui.SimpleLabel;


    import loom.store.Store;
    import loom.store.Product;
    import loom.store.Transaction;

    /**
     * Example for in app payment using the Loom Store API.
     *
     * WARNING: This example does not work out of box. Testing in app payment
     * on device requires that you have valid certificates, application ids, 
     * product ids, test accounts, and legal agreements in place with your
     * platform provider under your development account. This varies by 
     * platform, and requires setup. See the Loom Manual for details on getting 
     * set up for in app purchase.
     *
     * This application launches, queries the store for SKU information, then 
     * once information is received, it prompts you to purchase an item. As each
     * step completes it logs output and updates the app caption.
     */
    public class StoreExample extends Application
    {
        /// Label to display state of demo.        
        public var label:SimpleLabel;

        /// Called when app is ready to run.
        override public function run():void
        {
            // Provide a fell warning for new users.
            trace("********************************************************************************");
            trace("********************************************************************************");
            trace("********************************************************************************");
            trace("");
            trace("WARNING: This example does not work out of box. Testing in app payment");
            trace("on device requires that you have valid certificates, application ids, ");
            trace("product ids, test accounts, and legal agreements in place with your");
            trace("platform provider under your development account. This varies by ");
            trace("platform, and requires setup. See the Loom Manual for details on getting ");
            trace("set up for in app purchase.");
            trace("");
            trace("********************************************************************************");
            trace("********************************************************************************");
            trace("********************************************************************************");


            // Comment out this line to turn off automatic scaling.
            stage.scaleMode = StageScaleMode.LETTERBOX;

            // Setup standard demo UI.
            var bg = new Image(Texture.fromAsset("assets/bg.png"));
            bg.width = stage.stageWidth; 
            bg.height = stage.stageHeight; 
            stage.addChild(bg);
            
            var sprite = new Image(Texture.fromAsset("assets/logo.png"));
            sprite.center();
            sprite.x = 240;
            sprite.y = 120;
            stage.addChild(sprite);

            // Set up the label to show app state.
            label = new SimpleLabel("assets/Curse-hd.fnt", 320, 128);
            label.text = "Initializing...";
            label.x = stage.stageWidth/2 - 320/2;
            label.y = stage.stageHeight - 164;
            stage.addChild(label);

            // Register Store callbacks before initializing the store.

            // Called when product information is returned.
            Store.onProduct += function(p:Product):void
            {
                // Product provides a nice toString() implementation. But
                // check out its loom docs for a full reference.
                trace("PRODUCT: " + p.toString());
            };

            // Called when transaction information is received after
            // the purchase.
            Store.onTransaction +=  function (txn:Transaction):void
            {
                label.text = "Item bought!";

                // Transaction provides a nice toString() implementation. But
                // check out its loom docs for a full reference.
                trace("TRANSACTION: " + txn.toString());

                trace("New item bought!");
            };

            // Initialize the store. If there are pending transactions (for 
            // instance on Android the Play app can unload your app, then post
            // back transactions when it launches your app again) they will
            // be reported now. That's why we register callbacks beforehand.
            //
            // You can pass Store.DUMMY_PROVIDER to initialize() to use the
            // dummy provider, which always returns product data and always
            // allows purchases.
            trace("Initializing store...");
            Store.initialize(Store.DUMMY_PROVIDER);
            trace("   o done!");

            // Report the provider information.
            trace("   Using store provider: " + Store.providerName );
            trace("              available: " + Store.available );

            // Request product info. This is REQUIRED - for instance on iOS
            // your app will be rejected if you do not request product info
            // before doing a purchase.
            trace("Requesting product information...");
            label.text = "Loading Products!";
            Store.listProducts([
                    "co.theengine.loomplayer.billing.managedproduct", 
                    "co.theengine.loomplayer.billing.unmanaged",
                    "co.theengine.loomplayer.billing.subscription",
                    "co.theengine.loomplayer.billing.testconsumable",
                    ], onCompleteList);

            // Great - we'll get called back when the product listing operation
            // completes.
        }

        /// Called when the product info request is done.
        protected function onCompleteList():void
        {
            // Report to user.
            trace("Listing complete!");
            label.text = "Buying something!";

            // Request a purchase.
            trace("Initiating purchase...");
            Store.requestPurchase("co.theengine.loomplayer.billing.testconsumable", onPurchaseUIComplete);
        }

        /// Called when the purchse UI is gone; note it could be arbitrarily 
        /// long until the transaction is reported.
        protected function onPurchaseUIComplete():void
        {
            // Notify user; we don't need to do anything, we will receive
            // a transaction when the store API is done processing.
            trace("Purchase process completed, waiting for transaction!");
        }
    }
}