class unit { 

    static var gx = 0;
    static var gy = .3;

    // simple function for creatin an object
    // performs multiple onEnterFrame loops
    // which can be added with addWork(func)
    // method.
    // also adds a flag isWorker to an obj
    // requires for being a unit
    // will do nothing in case of calling
    // twice or with incorrect func
    static function multiWorker(o:Object){
        if (o.funcs != undefined)
            return o;
        if (o.isWorker == true)
            return o;
        o.funcs = new Array();
        o.isWorker = true;
        o.onEnterFrame = function(){
            for (var i = 0; i < this.funcs.length; ++i)
                this.funcs[i]();
        }
        o.addWork = function(func){ this.funcs.push(func); }
        return o;
    }

    // makes an object possible to 'stand' on world contours
    // adds methods
    // standOn(contour) -> place it to the start on the contour outside
    // standOn(...)     -> place it to the direct place
    // recalculate()    -> change stander position to a approximate place on contour
    //                     calls a contour .place function inside, then apply
    //                     coordinates and rotation changes
    static function stander(o:Object){
        o.standOn = function(wallContour){ return this.standOn(wallContour, 0, 0, false); }
        o.standOn = function(wallContour, segmentInd, segmentDist, isInsideContour){
            this.standingOn = wallContour;
            this.segmentInd = segmentInd;
            this.segmentDist = segmentDist;
            this.isInsideContour = isInsideContour;
            o.recalculate();
        }
        o.recalculate = function(){
            if (this.standingOn == null)
                return;
            this.standingOn.place(this);
            this._x = this.standingX; 
            this._y = this.standingY;
            this._rotation = this.standingAngle;
        }
        return o;
    }

    // makes an object possible to 'move' on world contours
    // strongly recommended to use it only after applying a stander property to obj
    // because it requires members `standingOn`, `segmentInd`, `segmentDist` and
    // a `recalculate`.
    static function mover(o:Object){
        o.moveSpd = 0;
        o.moveAcs = .3;
        o.moveSpdMax = 3;
        
        // leftRightMultiplier is -1 or 1
        // which shows a direction (to descreasing dist to the closest vertex -1
        // or to increase it +1, which also means clockwise or conter-clockwise order
        // of ongoing by the vertex indices).
        // also can be zero given, which will be threated as no desire to move
        // and will a slowing down or nothing will be countd
        o.groundMove = function(leftRightMultiplier){
            // if not on the ground, then can't move on it
            if (this.standingOn == null)
                return;
            // if no desire to move and no speed then do nothing
            if (!leftRightMultiplier && !this.moveSpd)
                return;
            // if a speed exists then slow down
            if (!leftRightMultiplier){
                this.moveSpd *= this.standingOn.speedNegation;
                if (Math.abs(this.moveSpd) < this.moveAcs)
                    this.moveSpd = 0;
                return;
            }
            // move left or right with an acseleration
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
        // add a work to move and check a new places moven to
        o.addWork(function(){
            if (o.moveSpd)
                o.segmentDist += o.moveSpd;
            // recalculate any frame, because of moving ground
            o.recalculate();
        });
        return o;
    }

    static var pushers = new Array();
    // makes object pushable and threated as a pusher
    // gives it a width and weight to interract with other
    // objects, which can be pushed (and also has width and weight)
    // adds inner methods of findCollision to detect a intersection
    // with other like objects
    static function pusher(o:Object, unitWeigth:Number, unitWidth:Number){
        o.unitWeigth = unitWeigth == undefined? (o._width * o._height) : unitWeigth;
        o.unitWidth = unitWidth == undefined? o._width : unitWidth;
        o.findCollision = function(){
            // can't collide with objects in air
            // TODO fix it
            if (this.standingOn == null)
                return null;
            // finds a collision accordign to the width intersections
            // returns a collide flag, collide side as a -1 and 1
            // and a collisionTarget - another pusahble obj
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
                }
            return null;
        }
        o.addWork(function(){
            // debug to show speed and standing on
            // TODO delete later
            _root[o._name + "_output"].text = 
                o._name + " stand on " + (o.standingOn == null? "none" : (o.standingOn._name + " _ " + o.standingOn.speedNegation)) + " seg id " + o.segmentInd + "  spd " + o.moveSpd;
            
            var collisionTarget = o.findCollision();
            if (collisionTarget == null)
                return;
            // compare an urge according to kinetic rules
            var v1 = o.moveSpd, v2 = collisionTarget.moveSpd, 
                m1 = o.unitWeigth, m2 = collisionTarget.unitWeigth;
            o.moveSpd = (2 * m2 * v2 + v1 * (m1 - m2)) / (m1 + m2);
            // set new move speed and create a half intersection width offset to
            // make objects uncollide again
            collisionTarget.moveSpd = (2 * m1 * v1 + v2 * (m2 - m1)) / (m1 + m2);
            o.segmentDist = collisionTarget.segmentDist - o.collideSide
                          * (o.unitWidth + collisionTarget.unitWidth + 1) * .5;
            o.recalculate();
        });
        pushers.push(o);
        return o;
    }

    // makes object jumpable
    // while object is on the ground (has contour to stand) it recieves an ability
    // to perform a jump, using `jump(spd)` method. While in air it will be movein
    // with all the rules, axelerating with (gx, gy) gravity.
    // it also can move in air as a controllable unit, using airMove, which requires
    // a members `airMoveAcs`, `airMoveSpdMax` defines a limits of this interaction;
    // each frame while in midair object will approximate a wall to land on,
    // then it will call a `land` method function.
    static function jumper(o:Object){
        o.flySpd = walls.point(0, 0);
        o.airMoveAcs = .3;
        o.airMoveSpdMax = 3;

        o.acselerateInAir = function(){
            this.flySpd._x += gx;
            this.flySpd._y += gy;
        }
        o.move = function(spd){ 
            this._x += spd._x;
            this._y += spd._y; 
        }
        o.airMove = function(leftRightMultiplier){
            if (this.standingOn != null || !leftRightMultiplier)
                return;
            if (leftRightMultiplier > 0){
                if (this.flySpd._x >= this.airMoveSpdMax)
                    return;
                this.flySpd._x += this.airMoveAcs;
            }else{
                if (this.flySpd._x <= - this.airMoveSpdMax)
                    return;
                this.flySpd._x -= this.airMoveAcs;
            }
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
            var jfrom = walls.point(this._x, this._y);
            var jto = walls.point(this._x + this.flySpd._x, this._y + this.flySpd._y);
            
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
            // check if a wall jumping from can move, then itll move itself
            var movingWall = this.standingOn.unit;
            if (movingWall != undefined){
                var jumpPoint = walls.point(this._x + this.flySpd._x, this._y + this.flySpd._y);
                var jumpAng = walls.angRad(this, jumpPoint) + Math.PI;
                var jumpStartSpd = walls.dist(this, jumpPoint)
                var v1 = jumpStartSpd, v2 = movingWall.moveSpd, 
                    m1 = this.unitWeigth, m2 = movingWall.unitWeigth;
                var moveWallAng = movingWall.standingOn.segmentAngs[movingWall.segmentInd] * Math.PI / 180;
                movingWall.moveSpd += Math.cos(moveWallAng - jumpAng)
                    * (2 * m1 * v1 + v2 * (m2 - m1)) / (m1 + m2);
            }
            // then make a unit jump
            // add a speed once to disconnect it from a base ground
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

                // also if a wall which a unit lands is a movable it should be moved
                // according to a speed and mass of unit landed
                var movingWall = this.standingOn.unit;
                if (movingWall != undefined){
                    var v1 = landSpd, v2 = movingWall.moveSpd, 
                        m1 = this.unitWeigth, m2 = movingWall.unitWeigth;
                    var moveWallAng = movingWall.standingOn.segmentAngs[movingWall.segmentInd] * Math.PI / 180;
                    movingWall.moveSpd += Math.cos(moveWallAng - jumpAng)
                        * (2 * m1 * v1 + v2 * (m2 - m1)) / (m1 + m2);
                }
            }   
            this.flySpd = walls.point(0, 0);
            // this.recalculate();
            this.swapButtonPallete();
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

    // makes an object controllable
    // should be included on a `mover or jumper` object, otherwise it would be no effects,
    // just a listener of keys. According to all main rules it proves a logick of controlling
    // a unit with a given keys aka (jump, left, down, right, up) pallete.
    // Also produces a feature of round swapping a pallete, depends on a object standing rotation
    // Warning: be carefull with a contours clockwise or conter-clockwise order, cause moving
    // will be happen to the minor-major indices, not according to x,y system.
    static function controll(o){
        o.keyframePallete = new Array(32, 65, 83, 68, 87);
        o.k = new Array(0, 1, 2, 3, 4);
        o.keyframePalleteNumber = new Array();
        o.keysClicked = new Array();
        o.keysPressed = new Array();
        o.previousStandingAngle = o.standingAngle;
        o.swapButtonPallete = function(){
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
        o.resetButtonPallete = function(){ this.k = new Array(0, 1, 2, 3, 4); }
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

            if (o.standingOn == null){
                var jumpDirection = o.keysPressed[o.k[3]] * 1 - o.keysPressed[o.k[1]] * 1;
                o.airMove(jumpDirection);
                return;
            }
            if (o.keysClicked[0]){
                o.jump(o.jumpInitialSpeed);
                o.resetButtonPallete();
                return;
            }
            var moveDirectionIsInside = 
                o.isInsideContour? -1 : 1;
            var moveDirection = 
                  (+ moveDirectionIsInside) * (o.keysPressed[o.k[1]] | o.keysPressed[o.k[2]])
                + (- moveDirectionIsInside) * (o.keysPressed[o.k[3]] | o.keysPressed[o.k[4]]);
            o.groundMove(moveDirection);
            if (!moveDirection)
                o.swapButtonPallete();
        });
        return o;
    }
}