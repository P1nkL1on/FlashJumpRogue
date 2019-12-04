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

    static var pushers = new Array();
    static function pusher(o:Object, unitWeigth:Number, unitWidth:Number){
        o.unitWeigth = unitWeigth == undefined? (o._width * o._height) : unitWeigth;
        o.unitWidth = unitWidth == undefined? o._width : unitWidth;
        o.findCollision = function(){
            if (this.standingOn == null)
                return null;
            for (var i = 0; i < pushers.length; ++i)
                if (pushers[i] != this){
                    var collisionTarget = pushers[i];
                    if (collisionTarget.standingOn != this.standingOn
                     || collisionTarget.segmentInd != this.segmentInd)
                        continue;
                    this.collide = Math.abs(this.segmentDist - collisionTarget.segmentDist) < (this.unitWidth + collisionTarget.unitWidth) * .5;
                    this.collideSide = this.segmentDist < collisionTarget.segmentDist? 1 : -1;
                    if (this.collide)
                        return collisionTarget;
                    // if (collisionTarget.standingOn != this.standingOn)
                    //     continue;
                    // var leftSideO = new Object(), rightSideO = new Object();
                    // leftSideO.segmentInd = rightSideO.segmentInd = this.segmentInd;
                    // leftSideO.segmentDist = this.segmentDist - .5 * this.unitWidth;
                    // rightSideO.segmentDist = this.segmentDist + .5 * this.unitWidth;
                    // this.standingOn.cropPos(leftSideO);
                    // this.standingOn.cropPos(rightSideO);
                    // this.collideSide = 
                    //     leftSideO.segmentInd == collisionTarget.segmentInd && leftSideO.segmentDist < collisionTarget.segmentDist + .5 * collisionTarget.unitWidth? 1 
                    //   : rightSideO.segmentInd == collisionTarget.segmentInd && rightSideO.segmentDist > collisionTarget.segmentDist - .5 * collisionTarget.unitWidth? -1 : 0;
                    // if (this.collide = (this.collideSide != 0))
                    //     return collisionTarget;
                }
            return null;
        }
        o.addWork(function(){
            _root[o._name + "_output"].text = 
                o._name + " stand on " + (o.standingOn == null? "none" : (o.standingOn._name + " _ " + o.standingOn.speedNegation)) + " seg id " + o.segmentInd + "  spd " + o.moveSpd;
            var collisionTarget = o.findCollision(o);
            if (collisionTarget == null)
                return;
            var v1 = o.moveSpd, v2 = collisionTarget.moveSpd, 
                m1 = o.unitWeigth, m2 = collisionTarget.unitWeigth;
            o.moveSpd = (2 * m2 * v2 + v1 * (m1 - m2)) / (m1 + m2);
            collisionTarget.moveSpd = (2 * m1 * v1 + v2 * (m2 - m1)) / (m1 + m2);
            o.segmentDist = collisionTarget.segmentDist - o.collideSide
                          * (o.unitWidth + collisionTarget.unitWidth + 1) * .5;
            o.recalculate();
        });
        pushers.push(o);
        return o;
    }

    /* static var jumpOffset = .00; */

    static function jumper(o:Object){
        o.flySpd = walls.point(0, 0);

        o.acselerateInAir = function(){
            this.flySpd._x += gx;
            this.flySpd._y += gy;
        }

        o.move = function(spd){ 
            this._x += spd._x;
            this._y += spd._y; 
        }
        o.wallsToCollide = walls.contours;
        o.wallsToCollideInside = new Array();
        o.calculateWallsInside = function(){
            this.wallsToCollide = walls.contours;
            this.wallsToCollideInside = new Array();
            for (var i = 0; i < this.wallsToCollide.length; ++i){
                var isInsideContour = raytrace.isInside(this, this.wallsToCollide[i]);
                this.wallsToCollideInside.push(isInsideContour);
            }
        }
        o.calculateWallsInside();

        o.findInAirCollision = function(){
            if (this.standingOn != null)
                return;
            var jfrom = walls.point(
                this._x/* +  this.flySpd._x * jumpOffset*/,
                this._y/* +  this.flySpd._y * jumpOffset*/);

            var jto = walls.point(
                this._x + this.flySpd._x /* * (1 + jumpOffset)*/,
                this._y + this.flySpd._y /* * (1 + jumpOffset)*/);
            
            for (var w = 0; w < this.wallsToCollide.length; ++w){
                var wall = this.wallsToCollide[w];
                var closestDistToLand = undefined;
                var closestInd = -1; var distToPoint;

                for (var i = 0; i < wall.pointInds.length - 1; ++i){
                    var pfrom = wall.p(i), pto = wall.p(i + 1);
                    var intersect = raytrace.intersect(jfrom, jto, pfrom, pto);
                    if (intersect == null)
                        continue;
                    // finally land
                    var distToLand  = walls.dist(intersect, jfrom);
                    if (closestDistToLand != undefined && closestDistToLand < distToLand)
                        continue;
                    closestInd = i;
                    closestDistToLand = distToLand;
                    distToPoint = walls.dist(intersect, pfrom);
                }
                if (closestInd < 0)
                    continue;

                var isLandInside = this.previousContour == wall? 
                    this.previosIsInsideContour : this.wallsToCollideInside[w];
                this.land(wall, closestInd, distToPoint, isLandInside);
                return;
            }

            // var wall = this.wallsToCollide[w];
            //     var bestDist = undefined, 
            //         segmentLandDist = undefined,
            //         bestDistSegmentInd = -1;
            //     for (var i = 0; i < wall.pointInds.length - 1; ++i){
            //         var pfrom = wall.p(i), pto = wall.p(i + 1);
            //         var intersect = raytrace.intersect(jfrom, jto, pfrom, pto);
            //         if (intersect == null)
            //             continue;
            //         var landDist = walls.dist(jfrom, intersect);
            //         if (bestDist != undefined && bestDist > landDist)
            //             continue;
            //         bestDist = landDist;
            //         bestDistSegmentInd = w;
            //         segmentLandDist = walls.dist(intersect, pfrom);
            //     }
            //     if (bestDistSegmentInd < 0)
            //         continue;
            //     var isLandInside = this.previousContour == wall? 
            //         this.previosIsInsideContour : this.wallsToCollideInside[w];
            //     trace(wall +' '+ bestDistSegmentInd +' '+ segmentLandDist +' '+ isLandInside);
            //     this.land(wall, bestDistSegmentInd, segmentLandDist, isLandInside);
            //     return;
        }

        o.previousContour = null;
        o.previosIsInsideContour = null;
        o.jump = function(jumpSpd){
            var jumpSpeedMultiplier = this.isInsideContour? 1 : -1;
            var jumpAngCos = this.standingOn.coss[this.segmentInd];
            var jumpAngSin = this.standingOn.sins[this.segmentInd];
            this.flySpd._y = - jumpAngCos * jumpSpd * jumpSpeedMultiplier;
            this.flySpd._x = + jumpAngSin * jumpSpd * jumpSpeedMultiplier;
            if (this.moveSpd != undefined){
                this.flySpd._x += jumpAngCos * this.moveSpd;
                this.flySpd._y += jumpAngSin * this.moveSpd;
                this.moveSpd = 0;
            }
            this._x += this.flySpd._x;
            this._y += this.flySpd._y;
            this.previousContour = this.standingOn;
            this.previosIsInsideContour = this.isInsideContour;
            this.standingOn = null;
            this.calculateWallsInside();
        }
        
        
        o.land = function(wallContour, segmentInd, segmentDist, isInsideContour){
            this.standOn(wallContour, segmentInd, segmentDist, isInsideContour);
            if (this.moveSpd != undefined){
                var wallAng = this.standingOn.segmentAngs[segmentInd] * Math.PI / 180;
                // var wallNormalAng = wallAng + (!isInsideContour? 1 : -1) * .5 * Math.PI;
                var jumpPoint = walls.point(this._x + this.flySpd._x, this._y + this.flySpd._y);
                var jumpAng = walls.angRad(this, jumpPoint);
                var landSpd = walls.dist(this, jumpPoint);
                this.moveSpd = Math.cos(wallAng - jumpAng) * landSpd;

                var movingWall = this.standingOn.unit;
                if (movingWall != undefined){
                    var v1 = landSpd, v2 = movingWall.moveSpd, 
                        m1 = this.unitWeigth, m2 = movingWall.unitWeigth;
                    var moveWallAng = movingWall.standingOn.segmentAngs[movingWall.segmentInd] * Math.PI / 180;
                    movingWall.moveSpd += Math.cos(moveWallAng - jumpAng)
                        * (2 * m1 * v1 + v2 * (m2 - m1)) / (m1 + m2);
                }
                
                // _root.lineStyle(1, 0xFF0000);
                // _root.moveTo(this._x, this._y);
                // _root.lineTo(jumpPoint._x, jumpPoint._y);
                // _root.lineStyle(1, 0x00FF00);
                // _root.moveTo(this._x, this._y);
                // _root.lineTo((jumpPoint._x + this._x) * .5, (jumpPoint._y + this._y) * .5);
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
        o.keysClicked = new Array();
        o.keysPressed = new Array();
        o.previousStandingAngle = o.standingAngle;
        o.swapKeyframePallete = function(){
            if (this.standingAngle == this.previousStandingAngle)
                return;
            var keyDownAD =     (this.standingAngle < 90 && this.standingAngle > -90);
            var keyUpAD =       (this.standingAngle > 90 || this.standingAngle < -90);
            var keyRightWS =    (this.standingAngle < 0 && this.standingAngle > -180);
            var keyLeftWS =     (this.standingAngle > 0 && this.standingAngle < 180);

            this.k[1] = keyDownAD? 1 : keyUpAD? 3 : this.k[1];
            this.k[3] = keyDownAD? 3 : keyUpAD? 1 : this.k[3];
            this.k[2] = keyRightWS? 2 : keyLeftWS? 4 : this.k[2];
            this.k[4] = keyRightWS? 4 : keyLeftWS? 2 : this.k[4];
            this.previousStandingAngle = this.standingAngle;
        }
        o.watchKeyPress = function(){
            for (var i = 0; i < this.keyframePallete.length; ++i){
                if (Key.isDown(this.keyframePallete[i]))
                    ++this.keyframePalleteNumber[i]; else this.keyframePalleteNumber[i] = 0;
                this.keysClicked[i] = this.keyframePalleteNumber[i] == 1;
                this.keysPressed[i] = this.keyframePalleteNumber[i] > 0;
            }
        }
        o.jumpInitialSpeed = 7;
        o.addWork(function(){
            o.watchKeyPress();
            if (o.standingOn == null)
                return;
            if (o.keysClicked[0])
                o.jump(o.jumpInitialSpeed);
            
            var moveDirectionIsInside = 
                o.isInsideContour? -1 : 1;
            var moveDirection = 
                  (+ moveDirectionIsInside) * (o.keysPressed[o.k[1]] | o.keysPressed[o.k[2]])
                + (- moveDirectionIsInside) * (o.keysPressed[o.k[3]] | o.keysPressed[o.k[4]]);
            o.groundMove(moveDirection);
            if (!moveDirection)
                o.swapKeyframePallete();
        });
        return o;
    }
}