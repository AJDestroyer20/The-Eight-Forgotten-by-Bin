package states;

import flixel.FlxG;
import flixel.FlxState;
import flixel.util.FlxTimer;
import flixel.input.keyboard.FlxKey;
import states.TitleState;
import hxvlc.flixel.FlxVideo;

class IntroState extends FlxState
{
    var video:FlxVideo;
    var isFirstTime:Bool = false;
    var canSkip:Bool = false;

    override public function create():Void
    {
        super.create();

        if (FlxG.save.data.hasOpenedBefore == null)
        {

            isFirstTime = true;
            canSkip = false;
            

            FlxG.save.data.hasOpenedBefore = true;
            FlxG.save.flush();
        }
        else
        {

            isFirstTime = false;
            canSkip = true;
        }

        video = new FlxVideo();
        video.onEndReached.add(function():Void
        {
            goToTitleState();
        });

        FlxG.addChildBelowMouse(video);

        if (video.load(Paths.video("intro")))
            new FlxTimer().start(0.001, (_) -> video.play());
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);


        if (canSkip && FlxG.keys.justPressed.ENTER)
        {
            goToTitleState();
        }
    }

    private function goToTitleState():Void
    {
        if (video != null)
        {
            video.dispose();
            FlxG.removeChild(video);
            video = null;
        }
        FlxG.switchState(new TitleState());
    }
}