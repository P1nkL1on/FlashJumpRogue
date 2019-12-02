import flash.geom.Matrix;
import flash.geom.Point;

class walls{
    static var points = new Array();

    static var contours = new Array();

    static function point(x, y){var o = new Object(); o._x = x; o._y = y; return o;}

    static function pushPoints(xys:Array){ for (var i = 0; i < xys.length; i += 2) points.push(point(xys[i], xys[i+1])); }

    static function dist2(pointA, pointB){return Math.pow(pointA._x - pointB._x, 2) + Math.pow(pointA._y - pointB._y, 2);}

    static function dist(pointA, pointB){return Math.sqrt(dist2(pointA, pointB));}

    static function angRad(pointA, pointB){return Math.atan2(pointB._y - pointA._y, pointB._x - pointA._x);}


    static var jumpOffset = .01;

    static function contour(pointInds:Array){
        var c = new Object();
        c._name = "Contour" + contours.length;
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
            var sa = this.segmentAngs[object.segmentInd]
                + !object.isInsideContour * 180
            while (sa > 180) sa -= 360; while (sa < -180) sa += 360;

            object.standingAngle = sa;
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

                jumper.land(this, i, distToPoint, jumper.previousContour == this?
                            jumper.previosIsInsideContour : isLandInside);  
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

    static function movingContour(o:Object){
        var count = 0;
        var indsArray = new Array();
        for (var i = 0; i < 20; ++i){
            var movingPoint = o["p" + i];
            if (movingPoint == undefined)
                break;
            indsArray.push(points.length);
            pushPoints(new Array(o._x + movingPoint._x, o._y + movingPoint._y));
        }
        o.contour = contour(indsArray);
        o.contour.unit = o;
        o.addWork(function(){
            for (var i = 0; i < o.contour.pointInds.length - 1; ++i){
                var m2 = o.transform.matrix;
                var m1 = m2.transformPoint(new Point(o["p" + i]._x, o["p" + i]._y));
                points[o.contour.pointInds[i]] = point(m1.x, m1.y);
            }
            o.contour.recalculate();
        });
        return o.contour;
    }

    // speedNegation = 0.9
    static function setGroundOptions(o, speedNegation){
        o.speedNegation = speedNegation;
        return o;
    }
}