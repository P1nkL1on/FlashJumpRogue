class unit { 
    static function multiWorker(o:Object){
        if (o.funcs != undefined)
            return o;
        o.funcs = new Array();
        o.onEnterFrame = function(){
            for (var i = 0; i < this.funcs.length; ++i)
                this.funcs[i]();
        }
        o.addWork = function(func){ this.funcs.push(func); }
        return o;
    }

    static function stander(o:Object){
        o.standOn = function(wallContour){ return this.standOn(wallContour, 0, 0, false); }
        o.standOn = function(wallContour, segmentInd, segmentDist, isInsideContour){
            this.standingOn = wallContour;
            this.segmentInd = segmentInd;
            this.segmentDist = segmentDist;
            this.isInsideContour = isInsideContour;
        }
        o.recalculate = function(){
            this.standingOn.cropPos(this);
            this.standingOn.place(this);
            //! move to another place
            this._x = this.standingX; 
            this._y = this.standingY;
            this._rotation = this.standingAngle;
        }
        o.addWork(function(){
            if (o.standingOn == null)
                return;
			if (Key.isDown(Key.LEFT))
				o.segmentDist -= 2;
			if (Key.isDown(Key.RIGHT))
				o.segmentDist += 2;
			o.recalculate();
        });
        return o;
    }

    static function jumper(o:Object){
        // falling work
        o.flySpd = walls.point(0, 0);
        o.acselerateInAir = function(){
            this.flySpd._x += -.05;
            this.flySpd._y += .1;
        }

        o.move = function(spd){ 
            if (o.standingOn != null)
                return;
            this._x += spd._x;
            this._y += spd._y; 
        }

        o.findInAirCollision = function(){
            for (var i = 0; i < walls.contours.length; ++i)
                if (o.standingOn == null)
                    walls.contours[i].findCollision(o);
        }

        o.jump = function(){
            this.standingOn = null;
        }
        
        o.finishJump = function(wallContour, segmentInd, segmentDist, isInsideContour){
            this.standOn(wallContour, segmentInd, segmentDist, isInsideContour);
            this.flySpd = walls.point(0, 0);
            this.recalculate();
        }

        o.addWork(function(){
            if (o.standingOn != null){
                if (Key.isDown(Key.SPACE))
                    o.jump();
                return;
            }
            o.acselerateInAir();
            o.findInAirCollision();
            o.move(o.flySpd);
        });

        return o;
    }
}