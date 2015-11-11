package simple
{
    public class Test
    {
        var member = "Member";

        public function Test()
        {
            trace("Test.ctor");
        }

        public function printMember()
        {
            trace(member);
        }
    }

    public class SimpleAssembly
    {
        public function SimpleAssembly()
        {
            trace("SimpleAssembly.ctor");
        }

        static var e = "Static";

        public static function main():void
        {
            trace("SimpleAssembly.main");
            trace(e);
            var obj = new SimpleAssembly();
            obj.run();
        }

        public function run():void
        {
            trace("SimpleAssembly.run");

            var t = new Test();
            t.printMember();
        }
    }
}
