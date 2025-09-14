package states;
import flixel.text.FlxText;
import flixel.FlxSprite;

class OutdatedState extends MusicBeatState
{
	public static var leftState:Bool = false;

	var warnText:FlxText;
	var disclaimerText:FlxText;
	override function create()
{
    super.create();
    var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
    add(bg);

    // gracias documentacion de flixel
    var image:FlxSprite = new FlxSprite(0, 0, Paths.image('tralalerotralala'));
    image.screenCenter();
    add(image);

    // Modify the text to show the disclaimer
    var disclaimerText:String = "ATTENTION! This is just a demo and all the content shown in it was created for mere humorous purposes and is not intended to be taken seriously, please, we do not want any problems. THANK YOU FOR YOUR ATTENTION!";
    warnText = new FlxText(0, 0, FlxG.width, disclaimerText, 32);
    warnText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER);
    warnText.screenCenter(Y);
    add(warnText);

    #if TOUCH_CONTROLS_ALLOWED
    addTouchPad('NONE', 'A_B');
    #end
}

	override function update(elapsed:Float)
	{
		if(!leftState) {
			if (controls.ACCEPT) {
				leftState = true;
				CoolUtil.browserLoad("https://es.memedroid.com/memes/detail/4581589");
			}
			else if(controls.BACK) {
				leftState = true;
			}

			if(leftState)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				FlxTween.tween(warnText, {alpha: 0}, 1, {
					onComplete: function (twn:FlxTween) {
						MusicBeatState.switchState(new MainMenuState());
					}
				});
			}
		}
		super.update(elapsed);
	}
}
