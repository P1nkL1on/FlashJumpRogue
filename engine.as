/*
    Currently replaced with walls.as as a
    more modern solution to contours engine
*/

class engine{
    // Setting up a world map with theese info
    // first is a simple array, containing points
    // which are any objects with fields x, y
    // {{10, 10}, {1, 10}, {1, 1}}
    static var wallPoints = new Array();
    // second is an PLANE array of indices, which would
    // be united into the cicled contours
    // in example below contours will be look like
    // {{1, 2, 3, 4,...}}
    //    x >
    // y
    // v
    //      3
    //      |  \
    //      2 -- 1
    // the order can be any (clockwise or conterclockwise)
    // and the player position (inside or out)
    // depends only on either where he will be spawned
    // and his further actions
    static var wallContours = new Array();
    // indices of objects starts
    // for the example previously shown it should be exactly
    // {0, 3, ...} to show the first contour contains only 3 points
    // 0, 1 and 2nd.
    static var wallContourStartInds = new Array();
    // PLANE dynamic array, which can store info about lenghes
    // of map edges (storing here after dist recalculations,
    // which happens only after moving one of the points in
    // the contour)
    // dists are calculated between next points:
    // first-second, second-third, ...., last-first
    // stored in exact order to be index consistent
    // {9.0, 9.0, 13.444, ...}
    static var wallContoursDists = new Array();


    // creates an object, which contains properties
    // x and y equals to coordinates according to default
    // flash world coordinates
    static function point(x, y){
        var pointObj = new Object();
        pointObj.x = x; 
        pointObj.y = y;
        return pointObj;
    }

    // add points to global arr
    // return indices of it to easy dynamic change
    // given indices can be threated as a Wall
    static function addWallPoints(newWallPoints){
        var wallPointIndices = new Array();
        for (var i = 0; i < newWallPoints.length; i++){
            wallPointIndices.push(wallPoints.length);
            wallPoints.push(newWallPoints[i]);
        }
        return wallPointIndices;
    }

    // add a given Wall to the global list of Walls
    // after this recalculates all walls edges lengthes
    static function addWallContour(wallContourIndices){
        // fill a zero to epmty starts array
        // if a first wall is adding
        if (wallContourStartInds.length == 0)
            wallContourStartInds.push(0);

        // add a zero to dists array as an uncalculated
        // push indices to array of indices
        for (var i = 0; i < wallContourIndices.length; i++){
            wallContoursDists.push(0);
            wallContours.push(wallContourIndices[i]);
        }
        // mark an end of current wall
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