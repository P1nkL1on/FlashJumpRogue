class prefab {
    static function player(o:Object){
        return unit.controll( 
            unit.jumper( 
                unit.pusher(
                    unit.mover( 
                        unit.stander( 
                            unit.multiWorker(o)
                        )
                    )
                , 500, 10)
            )
        );
    }

    static function movableObstacle(o:Object){
        unit.pusher(
            unit.mover(
                unit.stander(
                    unit.multiWorker(o)
                )
            )
        );
        o.addWork(function(){
            o.groundMove(0);
        });
        return o;
    }
}