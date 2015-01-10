package
{
    import loom.Application;
    import loom2d.display.StageScaleMode;
    import loom2d.display.Image;
    import loom2d.display.Sprite;
    import loom2d.display.DisplayObjectContainer;
    import loom2d.events.EventDispatcher;
    import loom2d.textures.Texture;
    import loom2d.ui.SimpleLabel;

    import org.robotlegs.mvcs.Context;
    import org.robotlegs.mvcs.Actor;
    import org.robotlegs.mvcs.Command;
    import org.robotlegs.mvcs.Mediator;
    import org.robotlegs.base.ContextEvent;

    import loom2d.events.TouchPhase;
    import loom2d.events.Touch;
    import loom2d.events.Event;
    import loom2d.events.TouchEvent;

    import feathers.controls.List;
    import feathers.controls.renderers.DefaultListItemRenderer;
    import feathers.controls.renderers.IListItemRenderer;
    import feathers.data.ListCollection;

    import feathers.themes.MetalWorksMobileTheme;

    import loom2d.textures.Texture;
    import loom2d.text.BitmapFont;
    import loom2d.text.TextField;

    /**
     * 
     */
    public class MyView extends Sprite
    {
        public var label:SimpleLabel;

        public var storeList:List;

        public static const CLICK_REFRESH = "click.refresh";

        public function initialize():void
        {
            var sprite = new Image(Texture.fromAsset("assets/logo.png"));
            sprite.center();
            sprite.x = stage.stageWidth / 2;
            sprite.y = stage.stageHeight / 2 + 50;
            addChild(sprite);

            label = new SimpleLabel("assets/Curse-hd.fnt");
            label.text = "Hello View!";
            label.center();
            label.x = stage.stageWidth / 2;
            label.y = stage.stageHeight / 2 - 100;
            label.addEventListener(TouchEvent.TOUCH, onClick);
            addChild(label);

            storeList = new List();
            storeList.dataProvider = new ListCollection(
                [
                {text: "Hi"},
                {text: "There"}
                ]);

            for(var i=0; i<10000; i++)
            {
                (storeList.dataProvider as ListCollection).push({text: "Yo" + i});
            }
            
            storeList.itemRendererFactory = function ():IListItemRenderer
             {
                 var renderer:DefaultListItemRenderer = new DefaultListItemRenderer();
                 renderer.labelField = "text";
                 renderer.iconSourceField = "thumbnail";
                 return renderer;
             };
            storeList.width = 200;
            storeList.height = 200;
            addChild(storeList);
        }

        protected function onClick(e:TouchEvent):void
        {
            var t = e.getTouch(label, TouchPhase.BEGAN);
            if(t)
                dispatchEventWith(CLICK_REFRESH);
        }
    }

    public class MyViewMediator extends Mediator
    {
        private var _view:MyView = null;

        public function set view(v:MyView)
        {
            _view = v;
        }

        [Inject]
        public function get view():MyView
        {
            return _view;
        }

        [Inject]
        public var stores:StoreManager;

        public override function onRegister():void
        {
            trace("I added a mediator to view " + view);
            view.initialize();

            stores.addEventListener("update", updateUi);

            view.addEventListener(MyView.CLICK_REFRESH, triggerUpdate);

            updateUi();
        }

        protected function triggerUpdate():void
        {
            dispatch(new Event("refresh"));
        }

        protected function updateUi():void
        {
            view.label.text = "Mediators Rule " + stores.list[0].avgCost;
            view.label.center();            
        }
    }

    public class HandleStartupCommand extends Command
    {
        [Inject]
        public var event:ContextEvent;

        override public function execute():void
        {
            trace("Hello startup! " + contextView + " " + event);
            contextView.addChild(new MyView());
        }
    }

    public class HandleRefreshCommand extends Command
    {
        [Inject]
        public var stores:StoreManager;

        override public function execute():void
        {
            stores.refresh();
        }

    }

    public class TestContext extends Context
    {
        public function TestContext(c:DisplayObjectContainer)
        {
            super(c);
        }

        override public function startup():void
        {
            trace("HELLO WORLD ");

            commandMap.mapEvent(ContextEvent.STARTUP_COMPLETE, HandleStartupCommand, ContextEvent);
            commandMap.mapEvent("refresh", HandleRefreshCommand);

            viewMap.mapType(MyView);

            mediatorMap.mapView(MyView, MyViewMediator);

            injector.mapValue(StoreManager, new StoreManager());

            super.startup();
        }
    }

    public class StoreVO
    {
        public var name:String;
        public var avgCost:Number;
        public var location:String;
    }

    public class StoreManager extends EventDispatcher
    {
        protected var _list:Vector.<StoreVO>;

        public function get list():Vector.<StoreVO>
        {
            if(!_list)
                initializeList();
            return _list;
        }

        protected function initializeList():void
        {
            var itemA = new StoreVO();
            itemA.name = "Bob's Store";
            itemA.avgCost = 20.00;
            itemA.location = "Bobtown";

            var itemB = new StoreVO();
            itemB.name = "Steve's Store";
            itemB.avgCost = 29.00;
            itemB.location = "Bobtown";

            var itemC = new StoreVO();
            itemC.name = "Tom's Store";
            itemC.avgCost = 200.00;
            itemC.location = "Bobtown";

            var itemD = new StoreVO();
            itemD.name = "Your Mom's Store";
            itemD.avgCost = 5.00;
            itemD.location = "Bobtown";

            _list = [itemA, itemB, itemC, itemD];
        }

        public function refresh():void
        {
            var l = list;
            for(var i=0; i<l.length; i++)
            {
                l[i].avgCost = Math.random() * 100;
            }

            dispatchEventWith("update");
        }
    }

    public class RobotLegs extends Application
    {
        public var context:TestContext;

        override public function run():void
        {
            // Comment out this line to turn off automatic scaling.
            stage.scaleMode = StageScaleMode.LETTERBOX;

            TextField.registerBitmapFont( BitmapFont.load( "assets/arialComplete.fnt" ), "SourceSansPro" );
            TextField.registerBitmapFont( BitmapFont.load( "assets/arialComplete.fnt" ), "SourceSansProSemibold" );

            new MetalWorksMobileTheme();

            // Setup anything else, like UI, or game objects.
            var bg = new Image(Texture.fromAsset("assets/bg.png"));
            bg.width = stage.stageWidth;
            bg.height = stage.stageHeight;
            stage.addChild(bg);
            
            trace("Starting TestContext");
            context = new TestContext(stage);
            context.startup();
        }
    }
}