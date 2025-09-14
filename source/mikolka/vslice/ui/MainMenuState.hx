package mikolka.vslice.ui;

import mikolka.compatibility.ui.MainMenuHooks;
import mikolka.compatibility.VsliceOptions;
#if !LEGACY_PSYCH
import states.TitleState;
#if MODS_ALLOWED
import states.ModsMenuState;
#end
import states.AchievementsMenuState;
import states.CreditsState;
import states.editors.MasterEditorMenu;
#else
import editors.MasterEditorMenu;
#end
import mikolka.compatibility.ModsHelper;
import mikolka.vslice.freeplay.FreeplayState;
import flixel.FlxObject;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import lime.app.Application;
import options.OptionsState;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxTween.FlxTweenType;
import mikolka.vslice.ui.StoryMenuState;
import flixel.math.FlxRect;
import flixel.math.FlxPoint;

class MainMenuState extends MusicBeatState
{
	#if !LEGACY_PSYCH
	public static var psychEngineVersion:String = '1.0.4';
	#else
	public static var psychEngineVersion:String = '0.6.3';
	#end
	public static var pSliceVersion:String = '3.1.1'; 
	public static var funkinVersion:String = '0.6.3';
	public static var curSelected:Int = 0;

	// Discord-style elements
	var leftSidebar:FlxSprite;
	var rightSidebar:FlxSprite;
	var mainArea:FlxSprite;
	var menuItems:FlxTypedGroup<FlxSprite>;
	var menuTexts:FlxTypedGroup<FlxText>;
	var serverIcons:FlxTypedGroup<FlxSprite>;
	var userCard:FlxSprite;
	var titleText:FlxText;
	var subtitleText:FlxText;

	// Discord colors
	static inline var DISCORD_DARK:Int = 0xFF2f3136;
	static inline var DISCORD_DARKER:Int = 0xFF202225;
	static inline var DISCORD_DARKEST:Int = 0xFF36393f;
	static inline var DISCORD_BLURPLE:Int = 0xFF5865f2;
	static inline var DISCORD_GREEN:Int = 0xFF57f287;
	static inline var DISCORD_TEXT:Int = 0xFFdcddde;
	static inline var DISCORD_TEXT_MUTED:Int = 0xFF72767d;

	// Responsive dimensions
	var screenWidth:Int;
	var screenHeight:Int;
	var leftSidebarWidth:Int = 72;
	var rightSidebarWidth:Int = 240;

	var optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		#if MODS_ALLOWED 'mods', #end
		#if ACHIEVEMENTS_ALLOWED 'awards', #end
		'credits',
		#if !switch 'donate', #end
		'options'
	];

	var optionNames:Map<String, String> = [
		'story_mode' => 'Story Mode',
		'freeplay' => 'Freeplay',
		'mods' => 'Mods',
		'awards' => 'Achievements',
		'credits' => 'Credits',
		'donate' => 'Donate',
		'options' => 'Options'
	];

	var camFollow:FlxObject;
	var selectedSomethin:Bool = false;
	
	// Variables para navegación con mouse - optimizadas
	var menuItemBounds:Array<FlxRect> = [];
	var hoveredItem:Int = -1;
	var lastMouseX:Float = 0;
	var lastMouseY:Float = 0;
	var mouseMovedThisFrame:Bool = false;
	
	// Variables para prevenir múltiples transiciones
	var transitionInProgress:Bool = false;
	var selectionTween:FlxTween;

	public function new(isDisplayingRank:Bool = false) {
		super();
	}

	override function create()
	{
		// Limpiar memoria antes de crear elementos
		Paths.clearUnusedMemory();
		ModsHelper.clearStoredWithoutStickers();
		ModsHelper.resetActiveMods();
		
		// Limpiar tweens previos para evitar conflictos
		FlxTween.globalManager.clear();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("En el menú principal", null);
		#end

		persistentUpdate = persistentDraw = true;

		// Get screen dimensions
		screenWidth = FlxG.width;
		screenHeight = FlxG.height;

		// Create Discord-style layout de manera más eficiente
		createDiscordLayoutOptimized();
		createServerIconsOptimized();
		createMenuItemsOptimized();
		createUserCardOptimized();
		
		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		changeItem();

		#if ACHIEVEMENTS_ALLOWED
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18) MainMenuHooks.unlockFriday();
		#if MODS_ALLOWED
		MainMenuHooks.reloadAchievements();
		#end
		#end

		#if TOUCH_CONTROLS_ALLOWED
		addTouchPad('LEFT_FULL', 'A_B_E');
		#end

		super.create();
		
		// Mantener la cámara fija en el centro de la pantalla
		FlxG.camera.follow(camFollow, null, 0.06);
		camFollow.setPosition(screenWidth / 2, screenHeight / 2);
	}

	function createDiscordLayoutOptimized()
	{
		// Crear sprites de fondo con menos llamadas a makeGraphic
		leftSidebar = new FlxSprite(0, 0);
		leftSidebar.makeGraphic(leftSidebarWidth, screenHeight, DISCORD_DARKEST);
		add(leftSidebar);

		rightSidebar = new FlxSprite(leftSidebarWidth, 0);
		rightSidebar.makeGraphic(rightSidebarWidth, screenHeight, DISCORD_DARKER);
		add(rightSidebar);

		var mainAreaX = leftSidebarWidth + rightSidebarWidth;
		var mainAreaWidth = screenWidth - mainAreaX;
		mainArea = new FlxSprite(mainAreaX, 0);
		mainArea.makeGraphic(mainAreaWidth, screenHeight, DISCORD_DARK);
		add(mainArea);

		// Crear elementos UI de manera más eficiente
		createUIElementsOptimized(mainAreaX, mainAreaWidth);
	}

	function createUIElementsOptimized(mainAreaX:Int, mainAreaWidth:Int)
	{
		// Title bar y search bar en un solo pase
		var titleBar = new FlxSprite(leftSidebarWidth, 0);
		titleBar.makeGraphic(rightSidebarWidth, 48, DISCORD_DARKEST);
		add(titleBar);

		var searchBar = new FlxSprite(leftSidebarWidth + 16, 8);
		searchBar.makeGraphic(rightSidebarWidth - 32, 32, 0xFF1e1f22);
		add(searchBar);

		// Textos con configuración optimizada
		var searchText = new FlxText(leftSidebarWidth + 24, 16, rightSidebarWidth - 48, "Find or start a conversation");
		searchText.setFormat(Paths.font("whitney.ttf"), 14, DISCORD_TEXT_MUTED, LEFT);
		add(searchText);

		titleText = new FlxText(mainAreaX + 20, 16, mainAreaWidth - 40, "Friday Night Funkin'");
		titleText.setFormat(Paths.font("whitney.ttf"), 24, FlxColor.WHITE, LEFT);
		add(titleText);

		subtitleText = new FlxText(mainAreaX + 20, 46, mainAreaWidth - 40, "Choose your adventure");
		subtitleText.setFormat(Paths.font("whitney.ttf"), 16, DISCORD_TEXT_MUTED, LEFT);
		add(subtitleText);

		// Welcome message
		var welcomeText = new FlxText(mainAreaX + 20, 100, mainAreaWidth - 40, "Welcome to Friday Night Funkin'!\nSelect an option from the menu on the left to get started.");
		welcomeText.setFormat(Paths.font("whitney.ttf"), 16, DISCORD_TEXT, LEFT);
		add(welcomeText);
	}

	function createServerIconsOptimized()
	{
		serverIcons = new FlxTypedGroup<FlxSprite>();
		add(serverIcons);

		var iconSize = 40;
		var iconX = (leftSidebarWidth - iconSize) / 2;
		
		// Home icon con texto integrado
		var homeIcon = new FlxSprite(iconX, 16);
		homeIcon.makeGraphic(iconSize, iconSize, DISCORD_BLURPLE);
		serverIcons.add(homeIcon);
		
		var homeText = new FlxText(iconX, 30, iconSize, "FNF");
		homeText.setFormat(Paths.font("whitney.ttf"), 12, FlxColor.WHITE, CENTER);
		add(homeText);

		// Separator
		var separator = new FlxSprite(iconX + 4, 68);
		separator.makeGraphic(32, 2, DISCORD_TEXT_MUTED);
		add(separator);

		// Server icons optimizados
		var serverData = [
			{color: 0xFF43b581, letter: "S"},
			{color: 0xFF5865f2, letter: "F"}, 
			{color: 0xFFfaa61a, letter: "M"},
			{color: 0xFFf04747, letter: "C"}
		];
		
		for (i in 0...serverData.length) {
			var yPos = 84 + (i * 56);
			var serverIcon = new FlxSprite(iconX, yPos);
			serverIcon.makeGraphic(iconSize, iconSize, serverData[i].color);
			serverIcons.add(serverIcon);
			
			var serverText = new FlxText(iconX, yPos + 12, iconSize, serverData[i].letter);
			serverText.setFormat(Paths.font("whitney.ttf"), 16, FlxColor.WHITE, CENTER);
			add(serverText);
		}
	}

	function createMenuItemsOptimized()
	{
		menuItems = new FlxTypedGroup<FlxSprite>();
		menuTexts = new FlxTypedGroup<FlxText>();
		add(menuItems);
		add(menuTexts);

		// DM header
		var dmHeader = new FlxText(leftSidebarWidth + 16, 64, rightSidebarWidth - 32, "DIRECT MESSAGES");
		dmHeader.setFormat(Paths.font("whitney.ttf"), 12, DISCORD_TEXT_MUTED, LEFT);
		add(dmHeader);

		// Pre-calcular posiciones para optimizar el bucle
		for (i in 0...optionShit.length) {
			var itemY = 92 + (i * 44);
			createSingleMenuItem(i, itemY);
		}
	}

	function createSingleMenuItem(index:Int, itemY:Int)
	{
		var option = optionShit[index];
		
		// Menu item background
		var menuItem = new FlxSprite(leftSidebarWidth + 8, itemY);
		menuItem.makeGraphic(rightSidebarWidth - 16, 40, 0x00000000);
		menuItems.add(menuItem);

		// Bounds para mouse
		menuItemBounds.push(new FlxRect(leftSidebarWidth + 8, itemY, rightSidebarWidth - 16, 40));

		// Status indicator
		var statusDot = new FlxSprite(leftSidebarWidth + 16, itemY + 8);
		statusDot.makeGraphic(8, 8, DISCORD_GREEN);
		add(statusDot);

		// Avatar
		var avatar = new FlxSprite(leftSidebarWidth + 32, itemY + 4);
		avatar.makeGraphic(32, 32, getMenuItemColor(option));
		add(avatar);

		// Main text
		var menuText = new FlxText(leftSidebarWidth + 72, itemY + 12, rightSidebarWidth - 88, optionNames.get(option));
		menuText.setFormat(Paths.font("whitney.ttf"), 16, DISCORD_TEXT, LEFT);
		menuTexts.add(menuText);

		// Subtitle
		var subtitleText = new FlxText(leftSidebarWidth + 72, itemY + 26, rightSidebarWidth - 88, getMenuSubtitle(option));
		subtitleText.setFormat(Paths.font("whitney.ttf"), 12, DISCORD_TEXT_MUTED, LEFT);
		add(subtitleText);
	}

	function createUserCardOptimized()
	{
		// User area
		userCard = new FlxSprite(leftSidebarWidth, screenHeight - 80);
		userCard.makeGraphic(rightSidebarWidth, 80, DISCORD_DARKEST);
		add(userCard);

		// User elements en un solo pase
		var userAvatar = new FlxSprite(leftSidebarWidth + 16, screenHeight - 64);
		userAvatar.makeGraphic(32, 32, DISCORD_BLURPLE);
		add(userAvatar);

		var userName = new FlxText(leftSidebarWidth + 56, screenHeight - 60, rightSidebarWidth - 72, "Player");
		userName.setFormat(Paths.font("whitney.ttf"), 14, FlxColor.WHITE, LEFT);
		add(userName);

		var userStatus = new FlxText(leftSidebarWidth + 56, screenHeight - 44, rightSidebarWidth - 72, "Playing FNF");
		userStatus.setFormat(Paths.font("whitney.ttf"), 12, DISCORD_TEXT_MUTED, LEFT);
		add(userStatus);

		// Version info
		var mainAreaX = leftSidebarWidth + rightSidebarWidth;
		var psychVer = new FlxText(mainAreaX + 20, screenHeight - 60, screenWidth - mainAreaX - 40, "Psych Engine " + psychEngineVersion);
		psychVer.setFormat(Paths.font("whitney.ttf"), 12, DISCORD_TEXT_MUTED, LEFT);
		add(psychVer);

		var fnfVer = new FlxText(mainAreaX + 20, screenHeight - 40, screenWidth - mainAreaX - 40, 'v${funkinVersion} (P-slice ${pSliceVersion})');
		fnfVer.setFormat(Paths.font("whitney.ttf"), 12, DISCORD_TEXT_MUTED, LEFT);
		add(fnfVer);
	}

	function getMenuItemColor(option:String):Int {
		return switch(option) {
			case 'story_mode': 0xFF43b581;
			case 'freeplay': 0xFF5865f2;
			case 'mods': 0xFFfaa61a;
			case 'awards': 0xFFf1c40f;
			case 'credits': 0xFFe67e22;
			case 'donate': 0xFFe91e63;
			case 'options': 0xFF95a5a6;
			default: DISCORD_TEXT_MUTED;
		}
	}

	function getMenuSubtitle(option:String):String {
		return switch(option) {
			case 'story_mode': 'Play the campaign';
			case 'freeplay': 'Free songs';
			case 'mods': 'Custom content';
			case 'awards': 'Your achievements';
			case 'credits': 'Meet the team';
			case 'donate': 'Support the game';
			case 'options': 'Settings';
			default: '';
		}
	}

	override function update(elapsed:Float)
	{
		// Optimizar actualización de volumen de música
		if (FlxG.sound.music != null && FlxG.sound.music.volume < 0.8) {
			FlxG.sound.music.volume = Math.min(0.8, FlxG.sound.music.volume + (0.5 * elapsed));
		}

		if (!selectedSomethin && !transitionInProgress) {
			// Optimizar navegación con mouse
			handleMouseNavigationOptimized();
			
			// Navegación con teclado
			if (controls.UI_UP_P)
				changeItem(-1);

			if (controls.UI_DOWN_P)
				changeItem(1);

			if (controls.BACK) {
				executeTransition(() -> MusicBeatState.switchState(new TitleState()), 'cancelMenu');
			}

			if (controls.ACCEPT || (FlxG.mouse.justPressed && hoveredItem != -1)) {
				handleMenuSelection();
			}

			if (#if TOUCH_CONTROLS_ALLOWED touchPad.buttonE.justPressed || #end 
				#if LEGACY_PSYCH FlxG.keys.anyJustPressed(ClientPrefs.keyBinds.get('debug_1').filter(s -> s != -1)) 
				#else controls.justPressed('debug_1') #end) {
				executeTransition(() -> MusicBeatState.switchState(new MasterEditorMenu()));
			}
		}

		super.update(elapsed);
	}

	function handleMouseNavigationOptimized():Void {
		var mouseX = FlxG.mouse.x;
		var mouseY = FlxG.mouse.y;
		
		// Solo procesar si el mouse se movió
		mouseMovedThisFrame = (mouseX != lastMouseX || mouseY != lastMouseY);
		if (!mouseMovedThisFrame) return;
		
		lastMouseX = mouseX;
		lastMouseY = mouseY;

		var newHoveredItem = -1;
		var mousePoint = FlxPoint.get(mouseX, mouseY);

		// Verificar bounds de manera más eficiente
		for (i in 0...menuItemBounds.length) {
			if (menuItemBounds[i].containsPoint(mousePoint)) {
				newHoveredItem = i;
				break;
			}
		}
		
		mousePoint.put(); // Reciclar el FlxPoint

		// Actualizar selección solo si cambió
		if (newHoveredItem != hoveredItem) {
			hoveredItem = newHoveredItem;
			
			if (hoveredItem != -1 && hoveredItem != curSelected) {
				curSelected = hoveredItem;
				changeItem(0);
			}
		}
	}

	function handleMenuSelection():Void {
		// Si se hace clic con mouse, verificar que esté sobre un elemento válido
		if (FlxG.mouse.justPressed && hoveredItem == -1) return;
		
		if (FlxG.mouse.justPressed && hoveredItem != -1) {
			curSelected = hoveredItem;
			changeItem(0);
		}
		
		FlxG.sound.play(Paths.sound('confirmMenu'));
		
		if (optionShit[curSelected] == 'donate') {
			CoolUtil.browserLoad('https://needlejuicerecords.com/pages/friday-night-funkin');
			return;
		}
		
		// Cancelar tween anterior si existe
		if (selectionTween != null) {
			selectionTween.cancel();
		}
		
		selectedSomethin = true;
		transitionInProgress = true;

		// Animación de selección optimizada
		selectionTween = FlxTween.tween(menuItems.members[curSelected], {alpha: 0.5}, 0.1, {
			type: FlxTweenType.PINGPONG,
			loopDelay: 0.1,
			onComplete: function(twn:FlxTween) {
				executeMenuAction();
			}
		});
	}

	function executeTransition(action:Void->Void, ?soundName:String = 'confirmMenu'):Void {
		if (transitionInProgress) return;
		
		transitionInProgress = true;
		selectedSomethin = true;
		
		FlxG.sound.play(Paths.sound(soundName));
		FlxTransitionableState.skipNextTransIn = false;
		FlxTransitionableState.skipNextTransOut = false;
		
		// Pequeño delay para que se escuche el sonido
		new FlxTimer().start(0.1, function(timer:FlxTimer) {
			action();
		});
	}

	function executeMenuAction() {
		// Limpiar tweens antes de cambiar estado
		if (selectionTween != null) {
			selectionTween.cancel();
			selectionTween = null;
		}
		
		switch (optionShit[curSelected]) {
			case 'story_mode':
				cleanupAndSwitchState(() -> MusicBeatState.switchState(new StoryMenuState()));
				
			case 'freeplay':
				// Manejo especial para Freeplay (substate)
				persistentDraw = true;
				persistentUpdate = false;
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;

				openSubState(new FreeplayState());
				subStateOpened.addOnce(state -> {
					// Restaurar estado de los elementos del menú
					for (i in 0...menuItems.members.length) {
						if (menuItems.members[i] != null) {
							menuItems.members[i].revive();
							menuItems.members[i].alpha = 1;
							menuItems.members[i].visible = true;
						}
					}
					selectedSomethin = false;
					transitionInProgress = false;
					changeItem(0);
				});

			#if MODS_ALLOWED
			case 'mods':
				cleanupAndSwitchState(() -> MusicBeatState.switchState(new ModsMenuState()));
			#end

			#if ACHIEVEMENTS_ALLOWED
			case 'awards':
				cleanupAndSwitchState(() -> MusicBeatState.switchState(new AchievementsMenuState()));
			#end

			case 'credits':
				cleanupAndSwitchState(() -> MusicBeatState.switchState(new CreditsState()));
				
			case 'options':
				cleanupAndSwitchState(() -> {
					MusicBeatState.switchState(new OptionsState());
					#if !LEGACY_PSYCH OptionsState.onPlayState = false; #end
					if (PlayState.SONG != null) {
						PlayState.SONG.arrowSkin = null;
						PlayState.SONG.splashSkin = null;
						#if !LEGACY_PSYCH PlayState.stageUI = 'normal'; #end
					}
				});
		}
	}

	function cleanupAndSwitchState(switchAction:Void->Void):Void {
		// Limpiar tweens activos
		FlxTween.globalManager.clear();
		
		// Limpiar memoria antes del cambio de estado
		Paths.clearUnusedMemory();
		
		// Ejecutar el cambio de estado
		switchAction();
	}

	function changeItem(huh:Int = 0) {
		// Limpiar highlight anterior
		if (curSelected >= 0 && curSelected < menuItems.members.length && menuItems.members[curSelected] != null) {
			menuItems.members[curSelected].makeGraphic(rightSidebarWidth - 16, 40, 0x00000000);
		}

		// Solo reproducir sonido para navegación con teclado
		if (huh != 0) {
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}
		
		curSelected += huh;

		// Wrap around
		if (curSelected >= optionShit.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = optionShit.length - 1;

		// Aplicar nuevo highlight
		if (curSelected >= 0 && curSelected < menuItems.members.length && menuItems.members[curSelected] != null) {
			menuItems.members[curSelected].makeGraphic(rightSidebarWidth - 16, 40, 0x33ffffff);
		}
	}

	override function destroy() {
		// Limpiar recursos al destruir el estado
		if (selectionTween != null) {
			selectionTween.cancel();
			selectionTween = null;
		}
		
		FlxTween.globalManager.clear();
		menuItemBounds = null;
		
		super.destroy();
	}
}
