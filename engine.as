class engine{

    // {{10, 10}, {1, 10}, {1, 1}
    static var wallPoints = new Array();
    // {{1, 2, 3}, {...}}
    static var wallContours = new Array();
    // {{9, 9}, {...}}
    static var wallContoursDists = new Array();

    static var wallContourStartInds = new Array();

    static function point(x, y){
        var pointObj = new Object();
        pointObj.x = x; 
        pointObj.y = y;
        return pointObj;
    }

    // add points to global arr
    // return indices of it to easy dynamic change
    static function addWallPoints(newWallPoints){
        var wallPointIndices = new Array();
        for (var i = 0; i < newWallPoints.length; i++){
            wallPointIndices.push(wallPoints.length);
            wallPoints.push(newWallPoints[i]);
        }
        return wallPointIndices;
    }
    
    static function setWallPoints(newWallPoints, newWallPoitnsIndices){
        for (var i = 0; i < newWallPoints.length; i++)
            wallPoints[newWallPoitnsIndices[i]] =
                newWallPoints[i];
    }

    static function addWallContour(wallContourIndices){
        if (wallContourStartInds.length == 0)
            wallContourStartInds.push(0);

        for (var i = 0; i < wallContourIndices.length; i++){
            wallContoursDists.push(0);
            wallContours.push(wallContourIndices[i]);
        }
        
        wallContourStartInds.push(wallContoursDists.length);
        recalculateWallContourDists();
    }

    static function recalculateWallContourDists(){
        trace('>' + wallContours);
        trace('>' + wallContoursDists);
        trace('~' + wallContourStartInds);

        for (var i = 1; i < wallContourStartInds.length; i++){
            var startContourInd = wallContours[wallContourStartInds[i-1]];
            var endContourInd = wallContours[wallContourStartInds[i]- 1];
            var firstPoint = wallPoints[startContourInd];
            for (var j = startContourInd + 1; j <= endContourInd; j++){
                var nextPoint = wallPoints[j];
                wallContoursDists[j-1] = dist(nextPoint, firstPoint);
                firstPoint = nextPoint;
            }
        }
        trace('+' + wallContours);
        trace('+' + wallContoursDists);
        trace('~' + wallContourStartInds);
    }

    static function dist(p0, p1){
        var dx = p0.x - p1.x, dy = p0.y - p1.y;
        return Math.sqrt(dx * dx + dy * dy);
    }

    //target - mc character to have this ability
    //wallContourInd - initial wall contour index
    //wallPointInd - initial wall contour's point index
    //wallPointDist - initial distance from that point
    //initial params can be left udnefined, so they would be required to set later
    static function setWallStander(target, wallContourInd, wallPointInd, wallPointDist){
        target.standingOnContourInd = wallContourInd;
        target.standingOnPointInd = wallPointInd;
        target.standingOnDist = wallPointDist;

    }


    static function test(){
        var pointsInds0 = addWallPoints(new Array(point(0, 0), point(10, 10), point(20, 10), point(30, 5)));
        var pointsInds1 = addWallPoints(new Array(point(0, 30), point(10, 40), point(20, 40), point(30, 45)));
        addWallContour(pointsInds0);
        addWallContour(pointsInds1);
    }
}