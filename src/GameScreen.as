package {

import flash.media.Sound;
import flash.media.SoundTransform;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.ui.Keyboard;
import flash.utils.getTimer;
import baseui.Screen;
import baseui.ScreenEvent;
import baseui.SoundPlayer;
import baseui.PlayListItem;

//  GameScreen
//
public class GameScreen extends Screen
{
  private const UNINITED:String = "UNINITED";
  private const INITED:String = "INITED";
  private const STARTED:String = "STARTED";
  private const GOALED:String = "GOALED";
  private const FINISHED:String = "FINISHED";

  private var _shared:SharedInfo;
  private var _course:Course;
  private var _status:Status;
  private var _title:Guide;
  private var _guide:SoundGuide;
  private var _soundman:SoundPlayer;

  private var _state:String;
  private var _tutorial:int;
  private var _ticks:int;

  public function GameScreen(width:int, height:int, shared:Object)
  {
    super(width, height, shared);
    _shared = SharedInfo(shared);

    _course = new Course(200, 200);
    _course.x = (width-_course.width)/2;
    _course.y = (height-_course.height)/2;
    addChild(_course);

    _status = new Status();
    _status.x = (width-_status.width)/2;
    _status.y = (height-_status.height-16);
    addChild(_status);
    
    _title = new Guide(width/2, height/8);
    _title.x = (width-_title.width)/2;
    _title.y = _course.y-_title.height-16;
    addChild(_title);

    _guide = new SoundGuide(_soundman, width/2, height/6);
    _guide.x = (width-_guide.width)/2;
    _guide.y = _status.y-_guide.height-16;
    addChild(_guide);

    _soundman = new SoundPlayer();

    addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
}

  // open()
  public override function open():void
  {
    _tutorial = 0;
    _ticks = 0;
    _soundman.isActive = true;

    _state = UNINITED;
    _title.show("RETAIN");
    _guide.show("PRESS KEY TO START");

    initGame();
  }

  // close()
  public override function close():void
  {
    _soundman.isActive = false;
  }

  // pause()
  public override function pause():void
  {
    _soundman.isActive = false;
  }

  // resume()
  public override function resume():void
  {
    _soundman.isActive = true;
  }

  // update()
  public override function update():void
  {
    if (_state == STARTED) {
      updateGame();
    }
    _ticks++;
  }

  // initGame()
  private function initGame():void
  {
    trace("initGame");
    _status.level = 0;
    _status.update();
    
    _state = INITED;
  }

  // startGame()
  private function startGame():void
  {
    trace("startGame");

    _state = STARTED;
  }

  // updateGame()
  private function updateGame():void
  {
  }

  // gameOver()
  private function gameOver():void
  {
    trace("gameOver");
    _title.show("GAME OVER");
    _guide.show("PRESS KEY TO PLAY AGAIN.");

    _state = UNINITED;
  }

  // nextLevel()
  private function nextLevel():void
  {
    trace("nextLevel");
    if (_status.level+1 < 100) {
      _status.level++;
      _status.update();
      //initLevel();
    } else {
      // Game beaten.
      _state = FINISHED;
      _title.show("CONGRATURATIONS!");
      _guide.show("PRESS KEY TO PLAY AGAIN.");
    }
  }

  // keydown(keycode)
  public override function keydown(keycode:int):void
  {
    _title.hide();
    _guide.hide();
    _soundman.reset();
    switch (_state) {
    case UNINITED:
      break;
    case GOALED:
      break;
    case STARTED:
      switch (keycode) {
      case Keyboard.F1:		// Cheat
      break;

      case Keyboard.LEFT:
	break;
      case Keyboard.RIGHT:
	break;
      case Keyboard.UP:
	break;
      case Keyboard.DOWN:
	break;
      case Keyboard.SPACE:
	break;
      }
      break;
    }
  }

  // onMouseDown
  private function onMouseDown(e:MouseEvent):void
  {
    _title.hide();
    _guide.hide();
    _soundman.reset();
    switch (_state) {
    case UNINITED:
      initGame();
      return;
    case GOALED:
      return;
    }
  }

  // playSound
  private function playSound(sound:Sound, dx:int):void
  {
    sound.play(0, 0, Utils.soundTransform(1, dx));
  }
}

} // package

import flash.display.Shape;
import flash.display.Sprite;
import flash.display.Bitmap;
import flash.media.Sound;
import flash.utils.Dictionary;
import baseui.Font;
import baseui.SoundPlayer;


//  Status
// 
class Status extends Sprite
{
  public var level:int;
  public var health:int;
  public var time:int;

  private var _text:Bitmap;

  public function Status()
  {
    _text = Font.createText("LEVEL: 00   HEALTH: 00   TIME: 00", 0xffffff, 0, 2);
    addChild(_text);
  }

  public function update():void
  {
    var text:String = "LEVEL: "+Utils.format(level+1,2);
    text += "   HEALTH: "+Utils.format(health,2);
    text += "   TIME: "+Utils.format(Math.min(99,time),2);
    Font.renderText(_text.bitmapData, text);
  }
}


//  Guide
// 
class Guide extends Sprite
{
  private var _text:Bitmap;

  public function Guide(width:int, height:int, alpha:Number=0.2)
  {
    graphics.beginFill(0, alpha);
    graphics.drawRect(0, 0, width, height);
    graphics.endFill();
  }

  public function set text(v:String):void
  {
    if (_text != null) {
      removeChild(_text);
      _text = null;
    }
    if (v != null) {
      _text = Font.createText(v, 0xffffff, 2, 2);
      _text.x = (width-_text.width)/2;
      _text.y = (height-_text.height)/2;
      addChild(_text);
    }
  }

  public function show(text:String=null):void
  {
    this.text = text;
    visible = true;
  }

  public function hide():void
  {
    visible = false;
  }
}


//  SoundGuide
// 
class SoundGuide extends Guide
{
  private var _player:SoundPlayer;
  private var _played:Dictionary;

  public function SoundGuide(player:SoundPlayer,
			     width:int, height:int, alpha:Number=0.2)
  {
    super(width, height, alpha);
    _player = player;
    _played = new Dictionary();
    graphics.beginFill(0, alpha);
    graphics.drawRect(0, 0, width, height);
    graphics.endFill();
  }

  public function reset():void
  {
    _played = new Dictionary();
  }

  public function play(sound:Sound):void
  {
    if (_played[sound] === undefined) {
      // Do not play the same sound twice.
      _played[sound] = 1;
      _player.addSound(sound);
    }
  }
}


//  Course
// 
class Course extends Sprite
{
  public function Course(width:int, height:int)
  {
    graphics.beginFill(0);
    graphics.drawRect(0, 0, width, height);
    graphics.endFill();
  }

}
