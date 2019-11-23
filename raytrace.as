class raytrace {
    static function intersect(fromA, toA, fromB, toB){
        var dirA = walls.point(toA._x - fromA._x, toA._y - fromA._y);
        var dirB = walls.point(toB._x - fromB._x, toB._y - fromB._y);

        var dirAnegY = - dirA._y;
        var dirAposX = + dirA._x;
        var dA = - (dirAnegY * fromA._x + dirAposX * fromA._y);
        
        var dirBnegY = - dirB._y;
        var dirBposX = + dirB._x;
        var dB = - (dirBnegY * fromB._x + dirBposX * fromB._y);

        var resAfrom = dirBnegY * fromA._x + dirBposX * fromA._y + dB;
        var resAto   = dirBnegY * toA._x   + dirBposX * toA._y + dB;

        var resBfrom = dirAnegY * fromB._x + dirAposX * fromB._y + dA;
        var resBto   = dirAnegY * toB._x   + dirAposX * toB._y + dA;

        if (resAfrom * resAto >= 0 || resBfrom * resBto >= 0)
            return null;

        var koef = resAfrom / (resAfrom - resAto);
        return walls.point(fromA._x + koef * dirA._x, fromA._y + koef * dirA._y);
    }
}