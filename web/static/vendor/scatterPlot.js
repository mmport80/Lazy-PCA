"use strict"

const _ = require('lodash');
const numeric = require('numeric');
const d3 = require('d3');

//*****************************************************
//process data here
//expect data to be correct frequency, date ranges etc
//calc returns + analytics
//display chart

const getLaggedVectors = d =>
  {
  const before = _.chain(d).tail().value();
  const after = _.chain(d).initial().value();
  return [before, after];
  }

const getReturns = d => {
  var [before, after] = getLaggedVectors(d);
  const returns = numeric.log(
    numeric['/'](after, before)
    );
  return returns;
  }

const elmProcessData = d =>
  {
  const closePrices = d.map(x => x[6]);

  const returns = getReturns(closePrices);
  const mean = jStat.mean(returns);
  const demeanedReturns = numeric['-'](returns, mean);
  const lVectors = getLaggedVectors(demeanedReturns)
  const vcv = numeric.dot(lVectors, numeric.transpose(lVectors));
  const vcv_normed = numeric.mul(vcv, 1/(lVectors[0].length-1));
  const result = numeric.eig(vcv_normed);

  const dates = d.map(x => x[0]);

  //expected date / datum
  const datesAndReturns = _.chain(returns)
    .zip(dates)
    .initial()
    .map(
      x => ({datum: x[0], date: x[1]})
      )
    .value();

  const data = getLaggedVectors(datesAndReturns);



  console.log('1');
  console.log(data);

  return {data:data, result:result};
  }

//****************************************************
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

function getScatterPlot(data, svdResult){
        //calculate means for each time series

        const mean = data.map( rs => jStat( rs.map( r => r.datum ) ).mean() );

        var data = _.chain(data[0])
          .zip(data[1])
          .map( i =>
            ( {date:i[1].date, before:i[0].datum, after:i[1].datum} )
            )
          .value();

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

        //x axis
        svg.append("g")
                .attr("class", "x axis")
                .attr("transform", "translate(0," + height + ")")
                .call(xAxis.tickFormat( formatXLabel ) )
                .append("text")
                .attr("class", "label")
                .attr("x", width)
                .attr("y", -6)
                .text("Before");

        //y axis
        svg.append("g")
                .attr("class", "y axis")
                .call(yAxis.tickFormat( formatXLabel ) )
                .append("text")
                .attr("class", "label")
                .attr("transform", "rotate(-90)")
                .attr("y", 6)
                .attr("dy", ".71em")
                .text("After");

        //plot dots
        svg.selectAll(".dot")
                .data(data)
                .enter().append("circle")
                .attr("class", "dot")
                .attr("cx", function(d) { return x( d.before+mean[0]  ); })
                .attr("cy", function(d) { return y( d.after+mean[1]  ); })
                .attr("r", 12)
                .append("title")
                .text(function(d) { return "Date: "+d.date+"; Period Before: "+(100*d.before).toLocaleString()+"%; After: "+(100*d.after).toLocaleString()+"%"; });

        //vector rotations
        const rotateBy = Math.atan2( svdResult.E.x[0][0], svdResult.E.x[0][1] ) * 180 / Math.PI;

        //why -46?
        const radiiLabels =
          rotateBy > -46 ?
            ["Momentum","Mean Reversion"]
            :
            ["Mean Reversion","Momentum"];

        //fit ellipse to data
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

        //triangle for the pointers
        svg     .append('svg:defs')
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

        //mean / mom vectors
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

        //mean / mom vectors
        svg     .append("line")
                .attr("class", "line")
                .attr("x1",function(d) { return x( mean[0] ); })
                .attr("y1",function(d) { return y( mean[1] ); })
                .attr("x2",x( mean[0] ))
                .attr("y2",function(d) { return y( mean[1]+Math.sqrt( svdResult.lambda.x[1] )); })
                .attr("transform", "rotate("+rotateBy+", "+x( mean[0] )+", "+y( mean[1] )+")")
                .attr("marker-end","url(#Triangle)")
                .append("title")
                .text(function(d) { return radiiLabels[1]+": " + Math.abs(100*-Math.sqrt( svdResult.lambda.x[1] )).toLocaleString() + "% "; });

        //origin dot (where origin is the mean returns)
        svg     .append("circle")
                .attr("class", "dot black")
                .attr("cx", function(d) { return x( mean[0]  ); })
                .attr("cy", function(d) { return y( mean[1]  ); })
                .attr("r", 12)
                .append("title")
                .text(function(d) { return "Mean: "+(100*mean[0]).toLocaleString()+"%"; });
        }
//*****************************************************
