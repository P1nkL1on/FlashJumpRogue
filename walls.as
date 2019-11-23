class walls{
    static var points = new Array();

    static var contours = new Array();

    static function point(x, y){var o = new Object(); o._x = x; o._y = y; return o;}

    static function pushPoints(xys:Array){ for (var i = 0; i < xys.length; i += 2) points.push(point(xys[i], xys[i+1])); }

    static function dist2(pointA, pointB){return Math.pow(pointA._x - pointB._x, 2) + Math.pow(pointA._y - pointB._y, 2);}

    static function dist(pointA, pointB){return Math.sqrt(dist2(pointA, pointB));}

    static function angRad(pointA, pointB){return Math.atan2(pointB._y - pointA._y, pointB._x - pointA._x);}


    static var jumpOffset = .05;

    static function contour(pointInds:Array){
        var c = new Object();
        c.count = pointInds.length;
        c.pointInds = pointInds;
        c.pointInds.push(c.pointInds[0]);
        c.p = function(i){ return points[this.pointInds[i]]; }
        c.recalculate = function(){
            this.segmentDists = new Array();
            this.segmentAngs = new Array(); 
            this.sins = new Array();
            this.coss = new Array();
            for (var i = 0; i < this.pointInds.length - 1; ++i){
                var pfrom = this.p(i), pto = this.p(i + 1);
                this.segmentDists.push(dist(pfrom, pto));
                var ang = angRad(pfrom, pto);
                this.segmentAngs.push(ang / Math.PI * 180);
                this.sins.push(Math.sin(ang));
                this.coss.push(Math.cos(ang));
            }
        }
        c.place = function(object){
            if (object.standingOn != this)
                return;
            var x = this.p(object.segmentInd)._x + this.coss[object.segmentInd] * object.segmentDist;
            var y = this.p(object.segmentInd)._y + this.sins[object.segmentInd] * object.segmentDist;
            object.standingX = x;
            object.standingY = y;
            object.standingAngle = 
                this.segmentAngs[object.segmentInd]
                + !object.isInsideContour * 180;
        }
        c.cropPos = function(object){
            if (object.segmentDist >= 0 && object.segmentDist <= this.segmentDists[object.segmentInd])
                return true;
            while (object.segmentDist < 0){
                --object.segmentInd;
                if (object.segmentInd < 0)
                    object.segmentInd = this.count - 1;
                object.segmentDist += this.segmentDists[object.segmentInd];
            }
            while (object.segmentDist > this.segmentDists[object.segmentInd]){
                object.segmentDist -= this.segmentDists[object.segmentInd];
                ++object.segmentInd;
                if (object.segmentInd >= this.count)
                    object.segmentInd = 0;
            }
            return false;
        }
        c.findCollision = function(jumper){
            var jumperFrom = walls.point(
                jumper._x + jumper.flySpd._x * jumpOffset,
                jumper._y + jumper.flySpd._y * jumpOffset);
            var jumperTo = walls.point(
                jumper._x + jumper.flySpd._x * (1 + jumpOffset),
                jumper._y + jumper.flySpd._y * (1 + jumpOffset));
            
            for (var i = 0; i < this.pointInds.length - 1; ++i){
                var pfrom = this.p(i), pto = this.p(i + 1);
                var intersect = raytrace.intersect(jumperFrom, jumperTo, pfrom, pto);
                if (intersect == null)
                    continue;
                var distToPoint = dist(intersect, pfrom);
                var isLandInside = 
                    raytrace.isInside(jumper, this)
                    && !raytrace.isInside(jumperTo, this);

                jumper.land(this, i, distToPoint, isLandInside);  
            }
        }
        c.draw = function(){
            for (var i = 0; i < this.pointInds.length - 1; ++i){
                var pfrom = this.p(i), pto = this.p(i + 1);
                _root.moveTo(pfrom._x, pfrom._y);
                _root.lineTo(pto._x, pto._y + .1);
            }
        }
        c.recalculate();
        c.draw();
        contours.push(c);
        return c;
    }
}