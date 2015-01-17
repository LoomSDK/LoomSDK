package
{
    import loom.platform.AppData;


    //example class that stores all persistant data for the Player using Loom's AppData class
    class PlayerData extends AppData
    {
        //public vars
        public var NumClicks:int = 0;


        //constructor
        function PlayerData(filename:String, appFolder:String, saveOnSet:Boolean, saveOnDeactivate:Boolean)
        {
            //initialize AppData
            super(filename, appFolder, saveOnSet, saveOnDeactivate);
        }


        //custom load
        override public function load():Boolean
        {
            //call base to load the JSON data first
            if(!super.load())
            {
                return false;
            }

            //NOTE: You can write custom code to post-process the read-in JSON, or do custom object management of the JSON object
            NumClicks = jsonData.getInteger("NumClicks");
            return true;
        }


        //custom save
        override public function save():Boolean
        {
            //NOTE: You can write custom code to pre-process the data (ie. custom object management) before doing final saving of the JSON

            //call the base to save out the JSON now
            return super.save();
        }


        //custom clear
        override public function clear():void
        {
            //call base clear erase the JSON
            super.clear();

            //NOTE: You can write custom code to clear any local custom data
            NumClicks = 0;
        }
    }
}