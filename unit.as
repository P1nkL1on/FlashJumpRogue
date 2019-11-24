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
            o.segmentDist += o.moveSpd;
			o.recalculate();
        });

        return o;
    }

    static function jumper(o:Object){
        o.jumpInitialSpeed = 7;
        o.flySpd = walls.point(0, 0);


        o.acselerateInAir = function(){
            this.flySpd._x += gx;
            this.flySpd._y += gy;
        }

        o.move = function(spd){ 
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
            this.flySpd._x = + this.standingOn.sins[this.segmentInd] * this.jumpInitialSpeed * speedMultiplier;
            if (this.moveSpd != undefined){
                this.flySpd._x += this.standingOn.coss[this.segmentInd] * this.moveSpd;
                this.flySpd._y += this.standingOn.sins[this.segmentInd] * this.moveSpd;
                this.moveSpd = 0;
            }
            this.standingOn = null;
        }
        
        o.land = function(wallContour, segmentInd, segmentDist, isInsideContour){
            this.standOn(wallContour, segmentInd, segmentDist, isInsideContour);
            if (this.moveSpd != undefined){
                var wallAng = this.standingOn.segmentAngs[segmentInd] * Math.PI / 180;
                // var wallNormalAng = wallAng + (!isInsideContour? 1 : -1) * .5 * Math.PI;
                // trace(wallAng + '/' + wallNormalAng);
                var jumpPoint = walls.point(this._x + this.flySpd._x, this._y + this.flySpd._y);
                var jumpAng = walls.angRad(this, jumpPoint);
                // trace(wallAng - jumpAng);
                var difAng = wallAng - jumpAng;
                this.moveSpd = Math.cos(difAng) * walls.dist(this, jumpPoint);
            }   
            this.flySpd = walls.point(0, 0);
            this.recalculate();
            this.swapKeyframePallete();
        }

        o.addWork(function(){
            if (o.standingOn != null)
                return;
            o.acselerateInAir();
            o.findInAirCollision();
            o.move(o.flySpd);
        });

        return o;
    }

    static function controll(o){
        o.keyframePallete = new Array(32, 65, 83, 68, 87);
        o.k = new Array(0, 1, 2, 3, 4);
        o.keyframePalleteNumber = new Array();
        o.keyClicked = new Array();
        o.keyPressed = new Array();
        o.swapKeyframePallete = function(){
            if (this._rotation < 90 && this._rotation > -90){
                this.k[1] = 1; this.k[3] = 3;
            }
            if (this._rotation > 90 || this._rotation < -90){
                this.k[1] = 3; this.k[3] = 1;
            }
            if (this._rotation < 0 && this._rotation > -180){
                this.k[2] = 2; this.k[4] = 4;
            }
            if (this._rotation > 0 && this._rotation < 180){
                this.k[2] = 4; this.k[4] = 2;
            }
        }
        o.watchKeyPress = function(){
            for (var i = 0; i < this.keyframePallete.length; ++i){
                if (Key.isDown(this.keyframePallete[i]))
                    ++this.keyframePalleteNumber[i]; else this.keyframePalleteNumber[i] = 0;
                this.keyClicked[i] = this.keyframePalleteNumber[i] == 1;
                this.keyPressed[i] = this.keyframePalleteNumber[i] > 0;
            }
        }
        o.addWork(function(){
            o.watchKeyPress();
            if (o.standingOn == null)
                return;
            if (o.keyClicked[0])
                o.jump();
            var moveDirectionIsInside = 
                o.isInsideContour? -1 : 1;
            var moveDirection = 
                  (+ moveDirectionIsInside) * (o.keyPressed[o.k[1]] | o.keyPressed[o.k[2]])
                + (- moveDirectionIsInside) * (o.keyPressed[o.k[3]] | o.keyPressed[o.k[4]]);
            o.groundMove(moveDirection);
            if (!moveDirection)
                o.swapKeyframePallete();
        });
        return o;
    }
}