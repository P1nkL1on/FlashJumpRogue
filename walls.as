import flash.geom.Matrix;
import flash.geom.Point;

/*
    New version of vertex walking engine
*/

class walls{
    // world array of points (interfaces with _x, _y)
    static var points = new Array();

    // stores a worlds objects with signature below (in func contour)
    static var contours = new Array();

    // simple method for creating abstract (non movieclip) points to use in contours
    static function point(x, y){var o = new Object(); o._x = x; o._y = y; return o;}

    // push an array of given points to the world points array
    static function pushPoints(xys:Array){ for (var i = 0; i < xys.length; i += 2) points.push(point(xys[i], xys[i+1])); }

    static function pushPointObjects(pp:Array){for (var i = 0; i < pp.length; ++i) points.push(pp[i]);}

    // return ||x, y||2 euqclid distance between 2 point-interfaced objects
    static function dist2(pointA, pointB){return Math.pow(pointA._x - pointB._x, 2) + Math.pow(pointA._y - pointB._y, 2);}

    // returns regulat px distance between 2 points-interfaced objects
    static function dist(pointA, pointB){return Math.sqrt(dist2(pointA, pointB));}

    // return angle in rad from 1 point to another
    static function angRad(pointA, pointB){return Math.atan2(pointB._y - pointA._y, pointB._x - pointA._x);}

    // creates an closed-up contour from given indices
    // points are taken from a world array points
    // TODO: create an overload for creating from points excatly
    static function contour(pointInds:Array){
        var c = new Object();
        c._name = "Contour" + contours.length;
        c.count = pointInds.length;
        c.pointInds = pointInds;
        // make an array circled
        c.pointInds.push(c.pointInds[0]);
        // ez acsess to the circled points array by index
        c.p = function(i){ return points[this.pointInds[i]]; }
        // function to calculate a distances between points,
        // sins and coss of angles between them
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
        // function, which make given object 'stand' on a contour
        // Given object must contain fields:
        //   segmentInd      - index of edge on the contour, which it is standing on
        //                   After cropped will be 0 <= segmentInd <= N, N =  vertex count;
        //   segmentDist     - distance from the array-left point on the edge standing
        //                   After cropped will be 0 <= segmentDist < segmentLength;
        //   isInsideContour - shows wherether object is inside a contour or not
        //                   only matters on displaying objects rotation
        //                   origin coordinate is still the same;
        //   Example: 
        //                   segmentInd = 0, means an object is placed on edge
        //                   between vertex 0 and vertex 1;
        //                   segmentDist = 25, means an object is moved 25px from
        //                   vertex 0 to direction of vertex 1.
        //   Result:
        //                   not directly changes object coordinates, but
        //                   settings its `standingX`, `standingY`, `standingAngle`
        //                   params in case of different logick to follow it afterwards. 
        c.place = function(object){
            if (object.standingOn != this)
                return;
            // automaticly make all data valid
            this.cropPos(object);
            var x = this.p(object.segmentInd)._x + this.coss[object.segmentInd] * object.segmentDist;
            var y = this.p(object.segmentInd)._y + this.sins[object.segmentInd] * object.segmentDist;
            object.standingX = x;
            object.standingY = y;
            var sa = this.segmentAngs[object.segmentInd]
                + !object.isInsideContour * 180
            while (sa > 180) sa -= 360; while (sa < -180) sa += 360;
            object.standingAngle = sa;
        }
        // Params of object segmentDist and segmentInd can technicly be any valued, but to make them
        // consistent with contour, which is object standing exists a cropPos method, which validate it;
        // Segment dist param can be used to force a unit to move from one edge to another, so
        c.cropPos = function(object){
            // if segmentDist is in the current edge's limits do nothing
            if (object.segmentDist >= 0 && object.segmentDist <= this.segmentDists[object.segmentInd])
                return true;
            // if walked over previous element and makes a distance negative, then
            // descrease an segmentInd or cicle it if below zero, and makes the seg
            // dist to the remaining distance
            while (object.segmentDist < 0){
                --object.segmentInd;
                if (object.segmentInd < 0)
                    object.segmentInd = this.count - 1;
                object.segmentDist += this.segmentDists[object.segmentInd];
            }
            // all the same mirrored for coming over positive limit of edge/
            // to move to the further edge or cycle to first one
            while (object.segmentDist > this.segmentDists[object.segmentInd]){
                object.segmentDist -= this.segmentDists[object.segmentInd];
                ++object.segmentInd;
                if (object.segmentInd >= this.count)
                    object.segmentInd = 0;
            }
            return object.onSegmentEnter == undefined? true : object.onSegmentEnter();
        }
        // simple debug function to draw a given contour
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

    // hard function to threat a (movieclip) object as a moving
    // contour. Object requires a inner objects (or variable-member objects)
    // with names p0, p1.... pN which would be threated as a vertexes between
    // edges of a contour. The dumbest way to define them is to check any matchs
    // up to 20 vertexes (increase this const on big movable contours, but actually
    // try to avoid them) and then thread them as a new points and create a contour
    // on them. On every transform of object there should be a recalculation of global
    // coordinates of collider contours.
    // Produces for an object given a member 'contour' with ptr to a contour obj. 
    // The contour itself has a reverse link marked as member 'unit'     
    static function movingContour(o:Object){
        var count = 0;
        // store an points and indices array
        var indsArray = new Array();
        for (var i = 0; i < 20; ++i){
            var movingPoint = o["p" + i];
            if (movingPoint == undefined)
                break;
            indsArray.push(points.length);
            pushPoints(new Array(o._x + movingPoint._x, o._y + movingPoint._y));
        }
        // create a contour and back ptr
        o.contour = contour(indsArray);
        o.contour.unit = o;
        // creating a task to recalculate a contours refs 
        // according to the its points matrixes and itself position
        var recalculateTask = function(){
            for (var i = 0; i < o.contour.pointInds.length - 1; ++i){
                var m2 = o.transform.matrix;
                var m1 = m2.transformPoint(new Point(o["p" + i]._x, o["p" + i]._y));
                points[o.contour.pointInds[i]] = point(m1.x, m1.y);
            }
            o.contour.recalculate();
        };
        if (o.isWorker) o.addWork(recalculateTask); else o.onEnterFrame = recalculateTask;
        return o.contour;
    }

    // set a ground options of selected contour
    // speedNegation = 0.9
    static function setGroundOptions(o, speedNegation){
        o.speedNegation = speedNegation;
        return o;
    }
}