

//*****************************************************

//close prices
//column 11 is 'Adjusted Close' on Y!
//column 4 is 'Close' on Goog

function getQuandlCall(source, ticker, key){

        if (source == "GOOG"){
                var column = 4;
                }
        else if (source == "YAHOO") {
                var column = 6;
                }
        else if (source == "CBOE") {
                var column = 1;
                }

        return {
                url:'https://www.quandl.com/api/v1/datasets/'+source+'/'+ticker+'.json?column='+column+'&auth_token='+key,
                ticker:ticker
                };
        }
        
        
       
//*****************************************************
//make api call
xhr = function(){
        var xmlhttp = new XMLHttpRequest();
        xmlhttp.open("GET", this.url, false);
        xmlhttp.send();
        return JSON.parse(xmlhttp.responseText);
        }
        
Object.defineProperty(
        Object.prototype, 
        'xhr',
        {
                value: xhr,
                writable: true,
                configurable: true,
                enumerable: false
                }
        );
                
var getQuandlData = function(source,ticker){
        return Lazy.generate(
                function(){
                        return function(){
                                var key = document.getElementById('key').value;
                                
                                return getQuandlCall(source,ticker,key).xhr().data;
                                }
                                ;
                        }()
                )
                ;
        }
