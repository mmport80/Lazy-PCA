/*

    (c)2015 John Orford

    This file is part of Lazy PCA.

    Lazy PCA is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Lazy PCA is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with Lazy PCA.  If not, see <http://www.gnu.org/licenses/>.

*/


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

Number.prototype.roundTwo = function() {
        return Math.round(this*100) / 100;
        }
