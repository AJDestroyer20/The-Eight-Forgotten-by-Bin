package scripts;

import flixel.FlxG;
import flixel.util.FlxColor;

class WindowTransparency
{
    public static function makeTransparent():Void
    {
        FlxG.cameras.bgColor = FlxColor.TRANSPARENT;
        FlxG.camera.bgColor = FlxColor.TRANSPARENT;
    }

    public static function resetBackground():Void
    {
        FlxG.cameras.bgColor = FlxColor.BLACK;
        FlxG.camera.bgColor = FlxColor.BLACK;
    }
}
