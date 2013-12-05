/*
 PureMVC - Copyright(c) 2006-08 Futurescale, Inc., Some rights reserved.
 Your reuse is governed by the Creative Commons Attribution 3.0 United States License
*/
package org.puremvc.loomsdk.patterns.proxy
{
    import org.puremvc.loomsdk.interfaces.*;
    import org.puremvc.loomsdk.patterns.observer.*;
    import org.puremvc.loomsdk.patterns.facade.Facade;
    
    /**
     * A base <code>IProxy</code> implementation. 
     * 
     * <P>
     * In PureMVC, <code>Proxy</code> classes are used to manage parts of the 
     * application's data model. </P>
     * 
     * <P>
     * A <code>Proxy</code> might simply manage a reference to a local data object, 
     * in which case interacting with it might involve setting and 
     * getting of its data in synchronous fashion.</P>
     * 
     * <P>
     * <code>Proxy</code> classes are also used to encapsulate the application's 
     * interaction with remote services to save or retrieve data, in which case, 
     * we adopt an asyncronous idiom; setting data (or calling a method) on the 
     * <code>Proxy</code> and listening for a <code>Notification</code> to be sent 
     * when the <code>Proxy</code> has retrieved the data from the service. </P>
     * 
     * @see org.puremvc.loomsdk.core.model.Model Model
     */
    public class Proxy extends Notifier implements IProxy
    {

        public static var NAME:String = 'Proxy';
        
        /**
         * Constructor
         */
        public function Proxy( proxyName:String=null, data:Object=null ) 
        {
            
            this.proxyName = (proxyName != null)?proxyName:NAME; 
            if (data != null) setData(data);
        }

        /**
         * Get the proxy name
         */
        public function getProxyName():String 
        {
            return proxyName;
        }        
        
        /**
         * Set the data object
         */
        public function setData( data:Object ):void 
        {
            this.data = data;
        }
        
        /**
         * Get the data object
         */
        public function getData():Object 
        {
            return data;
        }        

        /**
         * Called by the Model when the Proxy is registered
         */ 
        public function onRegister( ):void {}

        /**
         * Called by the Model when the Proxy is removed
         */ 
        public function onRemove( ):void {}
        
        
        // the proxy name
        protected var proxyName:String;
        
        // the data object
        protected var data:Object;
    }
}