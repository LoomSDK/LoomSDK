/*
 PureMVC - Copyright(c) 2006-08 Futurescale, Inc., Some rights reserved.
 Your reuse is governed by the Creative Commons Attribution 3.0 United States License
*/
package org.puremvc.loomsdk.patterns.facade
{
    import system.reflection.Type;

    import org.puremvc.loomsdk.core.*;
    import org.puremvc.loomsdk.interfaces.*;
    import org.puremvc.loomsdk.patterns.observer.Notification;

    /**
     * A base Singleton <code>IFacade</code> implementation.
     * 
     * <P>
     * In PureMVC, the <code>Facade</code> class assumes these 
     * responsibilities:
     * <UL>
     * <LI>Initializing the <code>Model</code>, <code>View</code>
     * and <code>Controller</code> Singletons.</LI> 
     * <LI>Providing all the methods defined by the <code>IModel, 
     * IView, & IController</code> interfaces.</LI>
     * <LI>Providing the ability to override the specific <code>Model</code>,
     * <code>View</code> and <code>Controller</code> Singletons created.</LI> 
     * <LI>Providing a single point of contact to the application for 
     * registering <code>Commands</code> and notifying <code>Observers</code></LI>
     * </UL>
     * <P>
      * Example usage:
     * <listing>
     *    import org.puremvc.loomsdk.patterns.facade.&lowast;;
     * 
     *    import com.me.myapp.model.~~;
     *    import com.me.myapp.view.~~;
     *    import com.me.myapp.controller.~~;
     * 
     *    public class MyFacade extends Facade
     *    {
     *        // Notification constants. The Facade is the ideal
     *        // location for these constants, since any part
     *        // of the application participating in PureMVC 
     *        // Observer Notification will know the Facade.
     *        public static const GO_COMMAND:String = "go";
     *         
     *        // Override Singleton Factory method 
     *        public static function getInstance() : MyFacade {
     *            if (instance == null) instance = new MyFacade();
     *            return instance as MyFacade;
     *        }
     *         
     *        // optional initialization hook for Facade
     *        override public function initializeFacade() : void {
     *            super.initializeFacade();
     *            // do any special subclass initialization here
     *        }
     *    
     *        // optional initialization hook for Controller
     *        override public function initializeController() : void {
     *            // call super to use the PureMVC Controller Singleton. 
     *            super.initializeController();
     * 
     *            // Otherwise, if you're implmenting your own
     *            // IController, then instead do:
     *            // if ( controller != null ) return;
     *            // controller = MyAppController.getInstance();
     *         
     *            // do any special subclass initialization here
     *            // such as registering Commands
     *            registerCommand( GO_COMMAND, com.me.myapp.controller.GoCommand )
     *        }
     *    
     *        // optional initialization hook for Model
     *        override public function initializeModel() : void {
     *            // call super to use the PureMVC Model Singleton. 
     *            super.initializeModel();
     * 
     *            // Otherwise, if you're implmenting your own
     *            // IModel, then instead do:
     *            // if ( model != null ) return;
     *            // model = MyAppModel.getInstance();
     *         
     *            // do any special subclass initialization here
     *            // such as creating and registering Model proxys
     *            // that don't require a facade reference at
     *            // construction time, such as fixed type lists
     *            // that never need to send Notifications.
     *            regsiterProxy( new USStateNamesProxy() );
     *             
     *            // CAREFUL: Can't reference Facade instance in constructor 
     *            // of new Proxys from here, since this step is part of
     *            // Facade construction!  Usually, Proxys needing to send 
     *            // notifications are registered elsewhere in the app 
     *            // for this reason.
     *        }
     *    
     *        // optional initialization hook for View
     *        override public function initializeView() : void {
     *            // call super to use the PureMVC View Singleton. 
     *            super.initializeView();
     * 
     *            // Otherwise, if you're implmenting your own
     *            // IView, then instead do:
     *            // if ( view != null ) return;
     *            // view = MyAppView.getInstance();
     *         
     *            // do any special subclass initialization here
     *            // such as creating and registering Mediators
     *            // that do not need a Facade reference at construction
     *            // time.
     *            registerMediator( new LoginMediator() ); 
     * 
     *            // CAREFUL: Can't reference Facade instance in constructor 
     *            // of new Mediators from here, since this is a step
     *            // in Facade construction! Usually, all Mediators need 
     *            // receive notifications, and are registered elsewhere in 
     *            // the app for this reason.
     *        }
     *    }
     * </listing>
     * 
     * @see org.puremvc.loomsdk.core.model.Model Model
     * @see org.puremvc.loomsdk.core.view.View View
     * @see org.puremvc.loomsdk.core.controller.Controller Controller
     * @see org.puremvc.loomsdk.patterns.observer.Notification Notification
     * @see org.puremvc.loomsdk.patterns.mediator.Mediator Mediator
     * @see org.puremvc.loomsdk.patterns.proxy.Proxy Proxy
     * @see org.puremvc.loomsdk.patterns.command.SimpleCommand SimpleCommand
     * @see org.puremvc.loomsdk.patterns.command.MacroCommand MacroCommand
     */
    public class Facade implements IFacade
    {
        /**
         * Constructor. 
         * 
         * <P>
         * This <code>IFacade</code> implementation is a Singleton, 
         * so you should not call the constructor 
         * directly, but instead call the static Singleton 
         * Factory method <code>Facade.getInstance()</code>
         * Debug assert will fail if Singleton instance has already been constructed
         * 
         */
        public function Facade( ) {
            Debug.assert( instance == null, SINGLETON_MSG );

            if (instance != null) return;
            instance = this;
            initializeFacade();    
        }

        /**
         * Initialize the Singleton <code>Facade</code> instance.
         * 
         * <P>
         * Called automatically by the constructor. Override in your
         * subclass to do any subclass specific initializations. Be
         * sure to call <code>super.initializeFacade()</code>, though.</P>
         */
        protected function initializeFacade(  ):void {
            initializeModel();
            initializeController();
            initializeView();
        }

        /**
         * Facade Singleton Factory method
         * 
         * @return the Singleton instance of the Facade
         */
        public static function getInstance():IFacade {
            if (instance == null) instance = new Facade( );
            return instance;
        }

        /**
         * Initialize the <code>Controller</code>.
         * 
         * <P>
         * Called by the <code>initializeFacade</code> method.
         * Override this method in your subclass of <code>Facade</code> 
         * if one or both of the following are true:
         * <UL>
         * <LI> You wish to initialize a different <code>IController</code>.</LI>
         * <LI> You have <code>Commands</code> to register with the <code>Controller</code> at startup.</code>. </LI>          
         * </UL>
         * If you don't want to initialize a different <code>IController</code>, 
         * call <code>super.initializeController()</code> at the beginning of your
         * method, then register <code>Command</code>s.
         * </P>
         */
        protected function initializeController( ):void {
            if ( controller != null ) return;
            controller = Controller.getInstance();
        }

        /**
         * Initialize the <code>Model</code>.
         * 
         * <P>
         * Called by the <code>initializeFacade</code> method.
         * Override this method in your subclass of <code>Facade</code> 
         * if one or both of the following are true:
         * <UL>
         * <LI> You wish to initialize a different <code>IModel</code>.</LI>
         * <LI> You have <code>Proxy</code>s to register with the Model that do not 
         * retrieve a reference to the Facade at construction time.</code></LI> 
         * </UL>
         * If you don't want to initialize a different <code>IModel</code>, 
         * call <code>super.initializeModel()</code> at the beginning of your
         * method, then register <code>Proxy</code>s.
         * <P>
         * Note: This method is <i>rarely</i> overridden; in practice you are more
         * likely to use a <code>Command</code> to create and register <code>Proxy</code>s
         * with the <code>Model</code>, since <code>Proxy</code>s with mutable data will likely
         * need to send <code>INotification</code>s and thus will likely want to fetch a reference to 
         * the <code>Facade</code> during their construction. 
         * </P>
         */
        protected function initializeModel( ):void {
            if ( model != null ) return;
            model = Model.getInstance();
        }
        

        /**
         * Initialize the <code>View</code>.
         * 
         * <P>
         * Called by the <code>initializeFacade</code> method.
         * Override this method in your subclass of <code>Facade</code> 
         * if one or both of the following are true:
         * <UL>
         * <LI> You wish to initialize a different <code>IView</code>.</LI>
         * <LI> You have <code>Observers</code> to register with the <code>View</code></LI>
         * </UL>
         * If you don't want to initialize a different <code>IView</code>, 
         * call <code>super.initializeView()</code> at the beginning of your
         * method, then register <code>IMediator</code> instances.
         * <P>
         * Note: This method is <i>rarely</i> overridden; in practice you are more
         * likely to use a <code>Command</code> to create and register <code>Mediator</code>s
         * with the <code>View</code>, since <code>IMediator</code> instances will need to send 
         * <code>INotification</code>s and thus will likely want to fetch a reference 
         * to the <code>Facade</code> during their construction. 
         * </P>
         */
        protected function initializeView( ):void {
            if ( view != null ) return;
            view = View.getInstance();
        }

        /**
         * Register an <code>ICommand</code> with the <code>Controller</code> by Notification name.
         * 
         * @param notificationName the name of the <code>INotification</code> to associate the <code>ICommand</code> with
         * @param commandClassRef a reference to the Class of the <code>ICommand</code>
         */
        public function registerCommand( notificationName:String, commandClassRef:Type ):void 
        {
            controller.registerCommand( notificationName, commandClassRef );
        }

        /**
         * Remove a previously registered <code>ICommand</code> to <code>INotification</code> mapping from the Controller.
         * 
         * @param notificationName the name of the <code>INotification</code> to remove the <code>ICommand</code> mapping for
         */
        public function removeCommand( notificationName:String ):void 
        {
            controller.removeCommand( notificationName );
        }

        /**
         * Check if a Command is registered for a given Notification 
         * 
         * @param notificationName
         * @return whether a Command is currently registered for the given <code>notificationName</code>.
         */
        public function hasCommand( notificationName:String ) : Boolean
        {
            return controller.hasCommand(notificationName);
        }

        /**
         * Register an <code>IProxy</code> with the <code>Model</code> by name.
         * 
         * @param proxyName the name of the <code>IProxy</code>.
         * @param proxy the <code>IProxy</code> instance to be registered with the <code>Model</code>.
         */
        public function registerProxy ( proxy:IProxy ):void    
        {
            model.registerProxy ( proxy );    
        }
                
        /**
         * Retrieve an <code>IProxy</code> from the <code>Model</code> by name.
         * 
         * @param proxyName the name of the proxy to be retrieved.
         * @return the <code>IProxy</code> instance previously registered with the given <code>proxyName</code>.
         */
        public function retrieveProxy ( proxyName:String ):IProxy 
        {
            return model.retrieveProxy ( proxyName );    
        }

        /**
         * Remove an <code>IProxy</code> from the <code>Model</code> by name.
         *
         * @param proxyName the <code>IProxy</code> to remove from the <code>Model</code>.
         * @return the <code>IProxy</code> that was removed from the <code>Model</code>
         */
        public function removeProxy ( proxyName:String ):IProxy 
        {
            var proxy:IProxy;
            if ( model != null ) proxy = model.removeProxy ( proxyName );    
            return proxy;
        }

        /**
         * Check if a Proxy is registered
         * 
         * @param proxyName
         * @return whether a Proxy is currently registered with the given <code>proxyName</code>.
         */
        public function hasProxy( proxyName:String ) : Boolean
        {
            return model.hasProxy( proxyName );
        }

        /**
         * Register a <code>IMediator</code> with the <code>View</code>.
         * 
         * @param mediatorName the name to associate with this <code>IMediator</code>
         * @param mediator a reference to the <code>IMediator</code>
         */
        public function registerMediator( mediator:IMediator ):void 
        {
            if ( view != null ) view.registerMediator( mediator );
        }

        /**
         * Retrieve an <code>IMediator</code> from the <code>View</code>.
         * 
         * @param mediatorName
         * @return the <code>IMediator</code> previously registered with the given <code>mediatorName</code>.
         */
        public function retrieveMediator( mediatorName:String ):IMediator 
        {
            return view.retrieveMediator( mediatorName ) as IMediator;
        }

        /**
         * Remove an <code>IMediator</code> from the <code>View</code>.
         * 
         * @param mediatorName name of the <code>IMediator</code> to be removed.
         * @return the <code>IMediator</code> that was removed from the <code>View</code>
         */
        public function removeMediator( mediatorName:String ) : IMediator 
        {
            var mediator:IMediator;
            if ( view != null ) mediator = view.removeMediator( mediatorName );            
            return mediator;
        }

        /**
         * Check if a Mediator is registered or not
         * 
         * @param mediatorName
         * @return whether a Mediator is registered with the given <code>mediatorName</code>.
         */
        public function hasMediator( mediatorName:String ) : Boolean
        {
            return view.hasMediator( mediatorName );
        }

        /**
         * Create and send an <code>INotification</code>.
         * 
         * <P>
         * Keeps us from having to construct new notification 
         * instances in our implementation code.
         * @param notificationName the name of the notiification to send
         * @param body the body of the notification (optional)
         * @param type the type of the notification (optional)
         */ 
        public function sendNotification( notificationName:String, body:Object=null, type:String=null ):void 
        {
            notifyObservers( new Notification( notificationName, body, type ) );
        }

        /**
         * Notify <code>Observer</code>s.
         * <P>
         * This method is left public mostly for backward 
         * compatibility, and to allow you to send custom 
         * notification classes using the facade.</P>
         *<P> 
         * Usually you should just call sendNotification
         * and pass the parameters, never having to 
         * construct the notification yourself.</P>
         * 
         * @param notification the <code>INotification</code> to have the <code>View</code> notify <code>Observers</code> of.
         */
        public function notifyObservers ( notification:INotification ):void {
            if ( view != null ) view.notifyObservers( notification );
        }

        // Private references to Model, View and Controller
        protected var controller : IController;
        protected var model         : IModel;
        protected var view         : IView;
        
        // The Singleton Facade instance.
        protected static var instance : IFacade; 
        
        // Message Constants
        protected const SINGLETON_MSG    : String = "Facade Singleton already constructed!";
    
    }
}