package
{
    import loom.Application;
    import loom2d.display.Shape;
    import loom2d.display.Stage;
    import loom2d.display.StageScaleMode;
    import loom2d.display.SVG;
    import loom2d.display.TextFormat;
    import loom2d.events.Touch;
    import loom2d.events.TouchEvent;
    import loom2d.events.TouchPhase;
    import loom2d.Loom2D;
    import loom2d.math.Rectangle;
    import loom.gameframework.TimeManager;
    import loom.gameframework.LoomGroup;
    import system.Math;

    private enum ShapeType
    {
        Circle,
        Square,
        RoundedSquare,
        Path,
        Text,
        SVG,
    }

    // A separate class to hold const data
    private class Data
    {
        public static var strings:Vector.<String> = new Vector.<String>
        [
            "Hello",
            "World",
            "Loom",
            "Vector",
            "Graphics"
        ];
        public static var svg:Vector.<SVG> = new Vector.<SVG>
        [
            SVG.fromFile("assets/loom_vector_logo_mod.svg"),
            SVG.fromFile("assets/Hand_left.svg"),
            SVG.fromFile("assets/nano.svg")
        ];
    }

    public class Benchmark extends Application
    {
        private var time:TimeManager;
        private var frames:Number;
        private var totalTime:Number;
        private var avgDt:Number;
        private var overlay:Shape;
        // Format for overlay text
        private var overlayFormat:TextFormat;

        // Display string for the quality setting
        private var qualityStr:String;

        // Text format for the benchmark
        private var textFormat:TextFormat;

        // Constants
        private const SHAPE_INTERVAL:Number = 10;
        private const SHAPE_NUM_START:Number = 150;

        // Comment these out if you want to disable certian types, for ex. SVG
        private var shapeTypes:Vector.<ShapeType> = new Vector.<ShapeType> [
            ShapeType.Circle,
            ShapeType.Square,
            ShapeType.RoundedSquare,
            ShapeType.Path,
            ShapeType.Text,
            ShapeType.SVG
        ];

        public function generateShape():Shape
        {
            var shape = new Shape();

            var color = Math.randomRangeInt(0, 255) |
                        Math.randomRangeInt(0, 255) << 8 |
                        Math.randomRangeInt(0, 255) << 16;

            shape.graphics.lineStyle(Math.randomRange(1, 5), color);

            // 50% chance to fill the shape (if available)
            var fill:Boolean = Math.random() > 0.5;
            if (fill)
            {
                var color2 = Math.randomRangeInt(0, 255) |
                             Math.randomRangeInt(0, 255) << 8 |
                             Math.randomRangeInt(0, 255) << 16;
                shape.graphics.beginFill(color2, 1);
            }

            var type = shapeTypes[Math.randomRangeInt(0, shapeTypes.length - 1)];
            switch(type)
            {
                case ShapeType.Text:
                    var str = Data.strings[Math.randomRangeInt(0, Data.strings.length - 1)];
                    textFormat.color = color;
                    shape.graphics.textFormat(textFormat);
                    shape.graphics.drawTextLine(0, 0, str);
                    break;
                case ShapeType.SVG:
                    var svg = Data.svg[Math.randomRangeInt(0, Data.svg.length - 1)];
                    shape.graphics.drawSVG(svg, 0, 0, 0.25, 0.5);
                    break;
                case ShapeType.Circle:
                    var radius = Math.randomRange(5, 25);
                    shape.graphics.drawCircle(radius, radius, radius);
                    break;
                case ShapeType.Square:
                    shape.graphics.drawRect(
                        Math.randomRange(0, stage.stageWidth),
                        Math.randomRange(0, stage.stageHeight),
                        Math.randomRange(0, stage.stageWidth / 2),
                        Math.randomRange(0, stage.stageHeight / 2));
                    break;
                case ShapeType.RoundedSquare:

                    shape.graphics.drawRoundRect(
                        Math.randomRange(0, stage.stageWidth),
                        Math.randomRange(0, stage.stageHeight),
                        Math.randomRange(0, stage.stageWidth / 2),
                        Math.randomRange(0, stage.stageHeight / 2),
                        Math.randomRange(0, 15),
                        Math.randomRange(0, 15));
                    break;
                case ShapeType.Path:
                    shape.graphics.moveTo(0, 0);
                    shape.graphics.curveTo(
                        Math.randomRange(0, stage.stageWidth),
                        Math.randomRange(0, stage.stageHeight),
                        Math.randomRange(0, stage.stageWidth),
                        Math.randomRange(0, stage.stageHeight));
                    break;
            }

            if (fill)
            {
                shape.graphics.endFill();
            }

            shape.x = Math.randomRange(0, stage.stageWidth);
            shape.y = Math.randomRange(0, stage.stageHeight);

            return shape;
        }

        override public function run():void
        {
            stage.scaleMode = StageScaleMode.LETTERBOX;
            stage.color = 0x888888;

            TextFormat.load("sans", "assets/SourceSansPro-Regular.ttf");

            textFormat = new TextFormat("sans", 20, 0xFFFFFF, false);

            time = LoomGroup.rootGroup.getManager(TimeManager) as TimeManager;
            frames = 0;
            totalTime = 0;
            avgDt = 1;

            for (var i = 0; i < SHAPE_NUM_START; i++)
            {
                stage.addChild(generateShape());
            }

            overlay = new Shape();
            stage.addChild(overlay);
            overlayFormat = new TextFormat("sans", 14, 0xFFFFFF, false);
            overlay.graphics.textFormat(overlayFormat);

            stage.addEventListener(TouchEvent.TOUCH, onTouch);

            qualityStr = getQualityStr();
        }

        /**
         * Touch middle to cycle over different vector rendering qualities
         * Touch top to increase shape count
         * Touch bottom to decrease shape count
         */
        private function onTouch(e:TouchEvent):void
        {
            var t:Touch = e.getTouch(stage, TouchPhase.BEGAN);
            if (!t) return;
            if (t.globalY < stage.stageHeight / 3)
            {
                // Add new n shapes
                 for (var i = 0; i < SHAPE_INTERVAL; i++)
                    stage.addChildAt(generateShape(), stage.numChildren - 1);
            }
            else if (t.globalY > stage.stageHeight / 3 * 2)
            {
                // Remove first n shapes
                for (var j = 0; j < SHAPE_INTERVAL; j++)
                    if (stage.numChildren > 1)
                        stage.removeChildAt(0);
                    else
                        break;
            }
            else
            {
                // Change the rendering quality
                switch (stage.vectorQuality) {
                    case Stage.VECTOR_QUALITY_ANTIALIAS | Stage.VECTOR_QUALITY_STENCIL_STROKES:
                        stage.vectorQuality = Stage.VECTOR_QUALITY_ANTIALIAS;
                        trace("Vector quality set to ANTIALIAS");
                        break;
                    case Stage.VECTOR_QUALITY_ANTIALIAS:
                        stage.vectorQuality = Stage.VECTOR_QUALITY_STENCIL_STROKES;
                        trace("Vector quality set to STENCIL");
                        break;
                    case Stage.VECTOR_QUALITY_STENCIL_STROKES:
                        stage.vectorQuality = Stage.VECTOR_QUALITY_NONE;
                        trace("Vector quality set to NONE");
                        break;
                    default:
                        stage.vectorQuality = Stage.VECTOR_QUALITY_ANTIALIAS | Stage.VECTOR_QUALITY_STENCIL_STROKES;
                        trace("Vector quality set to ANTIALIAS and STENCIL");
                }
                qualityStr = getQualityStr();
            }
        }

        override public function onTick()
        {
            // FPS calculations
            frames++;
            totalTime += time.deltaTime;

            // half second average
            if (totalTime >= 0.5)
            {
                avgDt = totalTime / frames;
                frames = 0;
                totalTime = 0;
            }

            // Rotate the shapes so stuttering becomes visible
            for (var i = 0; i < stage.numChildren; i++)
            {
                var shape:Shape = stage.getChildAt(i) as Shape;

                if (shape == null)
                    continue;
                if (shape == overlay)
                    continue;

                shape.rotation += time.deltaTime;
            }
        }

        override public function onFrame()
        {
            overlay.graphics.clear();

            overlay.graphics.beginFill(0x000000);
            overlay.graphics.drawRect(0, 0, stage.stageWidth, 14);
            overlay.graphics.endFill();
            overlay.graphics.textFormat(overlayFormat);
            overlay.graphics.drawTextLine(0, 0, String.format("FPS: %0.1f Shapes: %d Quality: %s", 1 / avgDt, stage.numChildren - 1, qualityStr));
        }

        private function getQualityStr():String
        {
            switch (stage.vectorQuality)
            {
                case Stage.VECTOR_QUALITY_ANTIALIAS | Stage.VECTOR_QUALITY_STENCIL_STROKES:
                    return "Antialias & Stencil";
                case Stage.VECTOR_QUALITY_ANTIALIAS:
                    return "Antialias";
                case Stage.VECTOR_QUALITY_STENCIL_STROKES:
                    return "Stencil";
                case Stage.VECTOR_QUALITY_NONE:
                    return "None";
            }

            return "<unknown>";
        }
    }
}
