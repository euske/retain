package {

import flash.media.Sound;
import flash.media.SoundTransform;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.ui.Keyboard;
import baseui.Utils;
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
  private var _target:Target;
  private var _course:Course;
  private var _status:Status;
  private var _title:Guide;
  private var _guide:SoundGuide;
  private var _soundman:SoundPlayer;

  private var _state:String;
  private var _tutorial:int;
  private var _ticks:int;
  private var _vx:int;
  private var _vy:int;

  public function GameScreen(width:int, height:int, shared:Object)
  {
    super(width, height, shared);
    _shared = SharedInfo(shared);

    _target = new Target(40, 40);
    _course = new Course(200, 200, _target);
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

    graphics.beginFill(0, 0);
    graphics.drawRect(0, 0, width, height);
    graphics.endFill();

    addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
    addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
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
      updateGame(_ticks);
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

  // updateGame(t)
  private function updateGame(t:int):void
  {
    _target.update(t, _vx, _vy);
    _course.update(t);
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
    if (_state == INITED) {
      startGame();
    } else if (_state == STARTED) {
      switch (keycode) {
      case Keyboard.F1:		// Cheat
	break;
      case Keyboard.LEFT:
	_vx = -1;
	break;
      case Keyboard.RIGHT:
	_vx = +1;
	break;
      case Keyboard.UP:
	_vy = +1;
	break;
      case Keyboard.DOWN:
	_vy = -1;
	break;
      case Keyboard.SPACE:
	break;
      }
    }
  }

  // keyup(keycode)
  public override function keyup(keycode:int):void
  {
    if (_state == STARTED) {
      switch (keycode) {
      case Keyboard.LEFT:
      case Keyboard.RIGHT:
	_vx = 0;
	break;
      case Keyboard.UP:
      case Keyboard.DOWN:
	_vy = 0;
	break;
      }
    }
  }
  
  // onMouseDown
  private function onMouseDown(e:MouseEvent):void
  {
    trace("e="+e);
    switch (_state) {
    case STARTED:
      if (e.stageX < _course.x) {
	_vx = -1;
      } else if (_course.x+_course.width < e.stageX) {
	_vx = +1;
      }      
      if (e.stageY < _course.y) {
	_vy = +1;
      } else if (_course.y+_course.height < e.stageY) {
	_vy = -1;
      }      
      break;
    }
  }
  
  // onMouseUp
  private function onMouseUp(e:MouseEvent):void
  {
    _title.hide();
    _guide.hide();
    _soundman.reset();
    switch (_state) {
    case UNINITED:
      initGame();
      break;
    case INITED:
      startGame();
      break;
    case STARTED:
      _vx = 0;
      _vy = 0;
      break;
    case GOALED:
      break;
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
import flash.utils.getTimer;
import baseui.Font;
import baseui.Utils;
import baseui.SoundPlayer;
import baseui.SoundGenerator;
import baseui.SampleGenerator;


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
  private var _width:int;
  private var _height:int;
  private var _target:Target;
  
  public function Course(width:int, height:int, target:Target)
  {
    _width = width;
    _height = height;
    graphics.beginFill(0x000044);
    graphics.drawRect(0, 0, _width, _height);
    graphics.endFill();

    _target = target;
    addChild(_target);
    update(0);
  }

  public function update(ticks:int):void
  {
    _target.x = (_width*(1+_target.ax)-_target.width)/2;
    _target.y = (_height*(1-_target.ay)-_target.height)/2;
  }
}

class Target extends Sprite
{
  private const DC:Number = -Math.log(3);
  private const FC:Number = Math.log(5);
  
  private var _ax:Number;
  private var _ay:Number;
  private var _t0:int;
  private var _tnext:int;

  public var speed:Number = 0.5;

  public function Target(
    width:int, height:int,
    color:uint=0xffffff)
  {
    _ax = _ay = 0;
    _tnext = 0;

    graphics.lineStyle(1, color);

    graphics.moveTo(width*0.5, height*0.0);
    graphics.lineTo(width*0.5, height*0.3);
    graphics.moveTo(width*0.5, height*0.7);
    graphics.lineTo(width*0.5, height*1.0);
    graphics.moveTo(width*0.0, height*0.5);
    graphics.lineTo(width*0.3, height*0.5);
    graphics.moveTo(width*0.7, height*0.5);
    graphics.lineTo(width*1.0, height*0.5);
  }

  public function get ax():Number
  {
    return _ax;
  }
  public function get ay():Number
  {
    return _ay;
  }

  private function makeSound(
    tone:SampleGenerator, 
    envelope:SampleGenerator):Sound
  {
    var sound:SoundGenerator = new SoundGenerator();
    sound.tone = tone;
    sound.envelope = envelope;
    return sound;
  }

  public function update(ticks:int, vx:int, vy:int):void
  {
    var t:int = getTimer();
    if (_t0 == 0) { _t0 = t; }
    
    var dt:Number = (t-_t0)*0.001;
    if (_tnext < t) {
      var dur:Number = 0.2*Math.exp(DC*_ax);
      var freq:Number = 440*Math.exp(FC*_ay);
      var sound:Sound = makeSound(
	SoundGenerator.ConstSineTone(freq),
	SoundGenerator.CutoffEnvelope(dur));
      sound.play(0, 0, Utils.soundTransform(0, _ax*1.5));
      _tnext = t+dur*2000;
    }
    _t0 = t;

    _ax += (Utils.rnd(3)-1)*dt*speed;
    _ax += vx*dt*speed;
    _ax = Math.max(-1.0, Math.min(1.0, _ax));

    _ay += (Utils.rnd(3)-1)*dt*speed;
    _ay += vy*dt*speed;
    _ay = Math.max(-1.0, Math.min(1.0, _ay));
  }
}
