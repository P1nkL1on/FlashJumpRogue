class unit { 

    static var gx = 0;
    static var gy = .3;

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
            if (this.standingOn == null)
                return;
            this.standingOn.cropPos(this);
            this.standingOn.place(this);
            //! move to another place
            this._x = this.standingX; 
            this._y = this.standingY;
            this._rotation = this.standingAngle;
        }
        return o;
    }

    static function mover(o:Object){
        o.moveSpd = 0;
        o.moveAcs = .3;
        o.moveSpdMax = 3;
        
        // -1 or 1
        o.groundMove = function(leftRightMultiplier){
            if (this.standingOn == null)
                return;
            if (!leftRightMultiplier){
                this.moveSpd *= this.standingOn.speedNegation;
                if (Math.abs(this.moveSpd) < this.moveAcs)
                    this.moveSpd = 0;
                return;
            }
            if (leftRightMultiplier > 0){
                if (this.moveSpd >= this.moveSpdMax)
                    return;
                this.moveSpd += this.moveAcs;
            }else{
                if (this.moveSpd <= - this.moveSpdMax)
                    return;
                this.moveSpd -= this.moveAcs;
            }
        }

        o.addWork(function(){
            o.groundMove(Key.isDown(Key.LEFT) * (-1)
                       + Key.isDown(Key.RIGHT) * 1);
            o.segmentDist += o.moveSpd;
			o.recalculate();
        });

        return o;
    }

    static function jumper(o:Object){
        o.jumpInitialSpeed = 10;
        o.flySpd = walls.point(0, 0);


        o.acselerateInAir = function(){
            this.flySpd._x += gx;
            this.flySpd._y += gy;
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
            var speedMultiplier = this.isInsideContour? 1 : -1;
            this.flySpd._y = - this.standingOn.coss[this.segmentInd] * this.jumpInitialSpeed * speedMultiplier;
            this.flySpd._x = this.standingOn.sins[this.segmentInd] * this.jumpInitialSpeed * speedMultiplier;
            this.standingOn = null;
        }
        
        o.land = function(wallContour, segmentInd, segmentDist, isInsideContour){
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