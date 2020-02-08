class prefab {
    static function player(o:Object){
        unit.multiWorker(o);
        unit.stander(o);
        unit.mover(o);
        unit.pusher(o, 500, 10);
        unit.jumper(o);
        unit.limitAngle(o);
        unit.controll(o);
        return o;
    }

    static function movableObstacle(o:Object){
        unit.multiWorker(o);
        unit.stander(o);
        unit.mover(o);
        unit.pusher(o);
        o.addWork(function(){ o.groundMove(0); });
        return o;
    }
}