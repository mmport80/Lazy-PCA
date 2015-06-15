//*****************************************************
        
print = function(){
        console.log(this);
        }

Object.defineProperty(
        Object.prototype, 
        'print',
        {
                value: print,
                writable: true,
                configurable: true,
                enumerable: false
                }
        );
                        
//*****************************************************

Array.prototype.returns = function(){
        return this
                .reduce(
                        function(acc,cur){
                                if(acc.prev===null){
                                        return {result:[],prev:cur};
                                        }
                                else{
                                        return  {
                                                result: acc.result.concat( { date: cur.date, datum: Math.log(acc.prev.datum/cur.datum) } ), 
                                                prev: cur
                                                };
                                        }
                                }
                        ,{result:[],prev:null}
                        )
                .result;
        }

//*****************************************************

Array.prototype.deMean = function(){
        var xs = Lazy(this).pluck('datum').toArray();
        var m = jStat(xs).mean();
        return numeric.addVS(xs,-m);
        }
          
//*****************************************************

Number.prototype.yieldToDsft = function(){
        return Math.exp(-this/100);
        }
        
//*****************************************************

