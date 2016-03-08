"use strict"

//*****************************************************

//change var to const
//change function to fat arrow
//change if to ? : ternary operaters

function formatDate(date) {
        const   dated = new Date(date),
                year = dated.getFullYear();

        const m = '' + (dated.getMonth() + 1)
        const month =
          m.length < 2 ?
            '0' + m
            :
            m;

        const d = '' + dated.getDate()
        const day =
          d.length < 2 ?
            '0' + d
            :
            d;

        return [year, month, day].join('-');
        }

//*****************************************************
//process, remove, draw
function processRemoveDraw(g){
        //process
        //move this outside, so that it's processed beforehand
        const e = g.processData();
        //remove
        d3.select("svg").remove();
        //draw
        getScatterPlot(e.pss, e.result);
        }

//*****************************************************
//the guts
document.getElementById('submit')
        .addEventListener("click",
                function(){
                        //pull
                        const globalData = getData(document.getElementById('source').value,document.getElementById('ticker').value);

                        //enable
                        document.getElementById('startDate').disabled = false;
                        document.getElementById('endDate').disabled = false;

                        //set dates
                        document.getElementById('startDate').value = formatDate(globalData[globalData.length-1].date);
                        document.getElementById('endDate').value = formatDate(globalData[0].date);

                        //process
                        const e = globalData.processData();

                        //remove svg
                        d3.select("svg").remove();

                        //draw
                        getScatterPlot(e.pss, e.result);

                        //set listenrs
                        setListeners(globalData);
                        }
                );

//*****************************************************
function setListeners(g){
        document.getElementById('startDate')
                .addEventListener("change",
                        function(){
                                (new Date(document.getElementById('startDate').value)).getFullYear() > 1000 &&
                                (new Date(document.getElementById('startDate').value)).getFullYear() < 9999
                                        ?
                                        setStartDateListener(g)
                                        :
                                        null;
                                }
                        );

        document.getElementById('endDate')
                .addEventListener("change",
                        function(){
                                (new Date(document.getElementById('endDate').value)).getFullYear() > 1000 &&
                                (new Date(document.getElementById('endDate').value)).getFullYear() < 9999
                                        ?
                                        setEndDateListener(g)
                                        :
                                        null;
                                }
                        );

        document.getElementById('horizon')
                .addEventListener("change",
                        function(){
                                setHorizonListener(g);
                                }
                        );
        };

//*****************************************************
//once data is available, then update etc.
function setHorizonListener(g){
        processRemoveDraw(g);
        }

//*****************************************************
//process global data
//draw
function setStartDateListener(g){
        processRemoveDraw(g);
        }

//*****************************************************
//process global data
//draw
function setEndDateListener(g){
        processRemoveDraw(g);
        }

//*****************************************************
//get data
//process data
//draw chart

function getData(source,ticker){
        return getQuandlData(source,ticker)
                .take(1)
                //necessary to value() here?
                .value()
                [0]
                .map(
                        function(i){
                                return document.getElementById('yield').checked == true ?
                                        {date: new Date(i[0]), datum:i[1].yieldToDsft()}
                                        :
                                        {date: new Date(i[0]), datum:i[1]};
                                }
                        );
        }

//*****************************************************
//calc pca

//clean
//if price is 0 - as good as nothing - filter out
//ensure returns are calc'ed from contiguous days
//contiguous is 22nd - 23rd... etc
//or Fri - Mon

//what counts as contiguous days for other periods?
//a week - 5 contiguous days/weekends
//a month - 21 contiguous days/weekends
//a quarter - 63 contiguous days/weekends

var processData = function(){
        const sampling = +document.getElementById('horizon').value;
        const startDate = new Date(document.getElementById('startDate').value);
        const endDate = new Date(document.getElementById('endDate').value);

        const y = this
          .reduce(
            (a, c) => a + c.datum
            , 0
            )

        const d = this.filter(
                function(i,j){
                        return j % sampling === 0 &&
                          (i.date >= startDate) &&
                          (i.date <= endDate);
                        }
                );

        //filter by monthly, etc. returns
        //create another vector or arrays, zip up at the end...?
        //[before, after]

        //descending date

        //value() here, when data is needed for jstat
        //keep everything lazy beforehand

        const pss = [Lazy(d).last(d.length-1).toArray(), Lazy(d).take(d.length-1).toArray()]
                .map(
                        function(i){
                                return i
                                  .returns()
                                  //
                                  //assume zero returns are duds
                                  .filter( x => x.datum != 0 );
                                }
                        );

        const pss_demeaned = pss
                .map(
                        function(i){
                                return i.deMean();
                                }
                        );

        const vcv = numeric.dot(pss_demeaned,numeric.transpose(pss_demeaned));

        const vcv_normed = numeric.mul(vcv,1/(pss_demeaned[0].length-1));

        const result = numeric.eig(vcv_normed);

        return {pss:pss,result:result};
        }

Object.defineProperty(
        Object.prototype,
        'processData',
        {
                value: processData,
                writable: true,
                configurable: true,
                enumerable: false
                }
        );

//*****************************************************

function getScatterPlot(data, svdResult){

        const mean = data.map(function(i){return jStat( Lazy(i).pluck('datum').toArray() ).mean();});

        data = Lazy(data[0]).zip(data[1]).map(function(i){return {date:i[1].date.toLocaleDateString(), before:i[0].datum,after:i[1].datum};}).toArray();

        const margin = {top: 20, right: 20, bottom: 50, left: 50},
            width = window.innerHeight*0.75 - margin.left - margin.right,
            height = window.innerHeight*0.75 - margin.top - margin.bottom;

        const x = d3.scale.linear()
            .range([0, width]);

        const y = d3.scale.linear()
            .range([height, 0]);

        const color = d3.scale.category10();

        const xAxis = d3.svg.axis()
            .scale(x)
            .orient("bottom");

        const yAxis = d3.svg.axis()
            .scale(y)
            .orient("left");

        x.domain(d3.extent(data, function(d) { return d.before + mean[0]; })).nice();
        y.domain(d3.extent(data, function(d) { return d.after + mean[1]; })).nice();

        const formatXLabel = function(d){
          if (d.toLocaleString() === x.domain()[1].toLocaleString() ){
                  return (d*100).toLocaleString()+"%";
            }
          else {
                  return (d * 100).toLocaleString();
            }
          }

        const formatYLabel = function(d){
          if (d.toLocaleString() === y.domain()[1].toLocaleString() ){
                  return (d*100).toLocaleString()+"%";
            }
          else {
                  return (d * 100).toLocaleString();
            }
          }

        const svg = d3.select("#plot").append("svg")
                .attr("width", width + margin.left + margin.right)
                .attr("height", height + margin.top + margin.bottom)
                .append("g")
                .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

        svg.append("g")
                .attr("class", "x axis")
                .attr("transform", "translate(0," + height + ")")
                .call(xAxis.tickFormat( formatXLabel ) )
                .append("text")
                .attr("class", "label")
                .attr("x", width)
                .attr("y", -6)
                .text("Before");

        svg.append("g")
                .attr("class", "y axis")
                .call(yAxis.tickFormat( formatXLabel ) )
                .append("text")
                .attr("class", "label")
                .attr("transform", "rotate(-90)")
                .attr("y", 6)
                .attr("dy", ".71em")
                .text("After");

        svg.selectAll(".dot")
                .data(data)
                .enter().append("circle")
                .attr("class", "dot")
                .attr("cx", function(d) { return x( d.before+mean[0]  ); })
                .attr("cy", function(d) { return y( d.after+mean[1]  ); })
                .attr("r", 12)
                .append("title")
                .text(function(d) { return "Date: "+d.date+"; Period Before: "+(100*d.before).toLocaleString()+"%; After: "+(100*d.after).toLocaleString()+"%"; });

        const rotateBy = Math.atan2( svdResult.E.x[0][0], svdResult.E.x[0][1] ) * 180 / Math.PI;

        //why -46?
        const radiiLabels =
          rotateBy > -46 ?
            ["Momentum","Mean Reversion"]
            :
            ["Mean Reversion","Momentum"];

        svg     .append("ellipse")
                .attr("class", "ellipse")
                .attr("cx",function(d) { return x( mean[0] ); })
                .attr("cy",function(d) { return y( mean[1] ); })
                .attr("rx",function(d) {
                                        return x( x.domain()[0]+Math.sqrt( svdResult.lambda.x[0] ) );
                                        })
                .attr("ry",function(d) {
                                        return y( y.domain()[1]-Math.sqrt( svdResult.lambda.x[1] ) );
                                        })
                .attr("transform", "rotate("+rotateBy+", "+x( mean[0] )+", "+y( mean[1] )+")")
                .append("title")
                .text(function(d) { return      "Mean "+ (100*mean[0]).toLocaleString() + "%; " +
                                                radiiLabels[0]+": "    + Math.abs(100*Math.sqrt( svdResult.lambda.x[0] )).toLocaleString() + "%; " +
                                                radiiLabels[1]+": "    + Math.abs(100*-Math.sqrt( svdResult.lambda.x[1] )).toLocaleString() + "% "
                                                ; });

        svg
                .append('svg:defs')
                .append('svg:marker')
                .attr('id', 'Triangle')
                .attr('markerHeight', 3)
                .attr('markerWidth', 3)
                .attr('orient', 'auto')
                .attr('refX', 6)
                .attr('refY', 5)
                .attr('viewBox', '0 0 10 10')
                .append('svg:path')
                .attr('d', 'M 0 0 L 10 5 L 0 10 z');

        svg     .append("line")
                .attr("class", "line")
                .attr("x1",function(d) { return x( mean[0] ); })
                .attr("y1",function(d) { return y( mean[1] ); })
                .attr("x2",function(d) { return x( mean[0]+Math.sqrt( svdResult.lambda.x[0] )); })
                .attr("y2",y( mean[1] ))
                .attr("transform", "rotate("+rotateBy+", "+x( mean[0] )+", "+y( mean[1] )+")")
                .attr("marker-end","url(#Triangle)")
                .append("title")
                .text(function(d) { return radiiLabels[0]+": "    + Math.abs(100*Math.sqrt( svdResult.lambda.x[0] )).toLocaleString() + "%; "; });

        svg     .append("line")
                .attr("class", "line")
                .attr("x1",function(d) { return x( mean[0] ); })
                .attr("y1",function(d) { return y( mean[1] ); })
                .attr("x2",x( mean[0] ))
                .attr("y2",function(d) { return y( mean[1]+Math.sqrt( svdResult.lambda.x[1] )); })
                .attr("transform", "rotate("+rotateBy+", "+x( mean[0] )+", "+y( mean[1] )+")")
                .attr("marker-end","url(#Triangle)")
                .append("title")
                .text(function(d) { return radiiLabels[1]+": "    + Math.abs(100*-Math.sqrt( svdResult.lambda.x[1] )).toLocaleString() + "% "; });

        svg     .append("circle")
                .attr("class", "dot black")
                .attr("cx", function(d) { return x( mean[0]  ); })
                .attr("cy", function(d) { return y( mean[1]  ); })
                .attr("r", 12)
                .append("title")
                .text(function(d) { return "Mean: "+(100*mean[0]).toLocaleString()+"%"; });
        }
//*****************************************************
