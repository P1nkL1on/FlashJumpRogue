class mapeditor {
    static var controller;

    static function init(){

        walls.pushPoints(new Array(10, 10, 1190, 10, 1190, 790, 10, 790));
        walls.setGroundOptions(walls.contour(new Array(0, 1, 2, 3)), .95);


        controller = _root.attachMovie("empty", "mouseController", 0);
        var linePreview = controller.attachMovie("empty", "linePreview", 0);
        controller.currentPoints = new Array();
        controller.currentIndices = new Array();
        controller.buttons = new Array(49, 50, 51);
        controller.isPressed = new Array(); for (var i = 0; i < controller.buttons.length; ++i) controller.isPressed.push(false);

        controller.enterState = function(s){ if (this.isIn("none")) this.state = s; }
        controller.resetState = function(){ this.state = "none"; }
        controller.isIn = function(s) { return this.state == s; }
        controller.resetState();


        controller.p = function(i){ return this.currentPoints[i % this.currentPoints.length]; }
        controller.onMouseDown = function(){
            if (this.isIn("creating")){
                this.currentIndices.push(walls.points.length + this.currentPoints.length);
                this.currentPoints.push(walls.point(_root._xmouse, _root._ymouse));
                this.drawCurrentBuffer();
            }
        }
        controller.onMouseMove = function(){
            if (this.isIn("creating")){
                if (this.currentPoints.length == 0)
                    return;
                this.linePreview.clear();
                this.linePreview.lineStyle(1, 0x00FF00);
                var plast = this.currentPoints[this.currentPoints.length - 1],
                    pfirst= this.currentPoints[0];
                this.linePreview.moveTo(plast._x, plast._y);
                this.linePreview.lineTo(_root._xmouse, _root._ymouse);
                this.linePreview.lineTo(pfirst._x, pfirst._y);
            }
        }
        controller.onEnterFrame = function(){
            _root.state_text.text = this.state;
            for (var i = 0; i < this.buttons.length; ++i){
                this.isPressed[i] = Key.isDown(this.buttons[i])? (this.isPressed[i] + 1) : 0;
                if (this.isPressed[i] == 1)
                    this.onPressed(i);
            }
        }

        controller.onPressed = function(ind){
            switch(ind)
            {
                case 0: return this.isIn("creating")? this.addContour() : this.enterState("creating");
                case 1: return _root.hero == undefined? this.createHero() : this.respawnHero();
                case 2: return _root.hero == undefined? this.createHero(1) : this.respawnHero(1);
                default: return;
            }
        }

        controller.drawCurrentBuffer = function(){
            this.clear();
            this.lineStyle(1, 0xFF0000);
            for (var i = 0; i < this.currentPoints.length; ++i){
                 var pfrom = this.p(i), pto = this.p(i + 1);
                this.moveTo(pfrom._x, pfrom._y);
                this.lineTo(pto._x, pto._y);
            }
            this.updateAfterEvent();
        }

        controller.addContour = function(){
            if (this.state != "creating")
                return;
            // add changes to a global context
            // can't add a contour with 2 points only
            if (this.currentIndices.length > 2){
                walls.pushPointObjects(this.currentPoints);
                walls.setGroundOptions(walls.contour(this.currentIndices), .9);
            }

            // clean all
            this.currentPoints = new Array();
            this.currentIndices = new Array();
            this.clear();
            this.linePreview.clear();
            this.resetState();
        }
        controller.createHero = function(angleLimited){
            _root.player = prefab.player(_root.attachMovie("test_circle", "hero", _root.getNextHighestDepth()));
            this.respawnHero(angleLimited);
        }
        controller.respawnHero = function(angleLimited){
            _root.player._x = _root._xmouse; 
            _root.player._y = _root._ymouse;
            _root.player.standingOn = null;
            _root.player.moveAcsForce = 0;
            _root.player.flySpd = walls.point(0, 0);
            if (angleLimited != undefined) unit.limitAngle(_root.hero); else _root.hero.onSegmentEntered = undefined;
            _root.hero.gotoAndStop(angleLimited == undefined? 1 : 2);
        }
    }
}