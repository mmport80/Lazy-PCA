"use strict"

const _ = require('lodash');
const numeric = require('numeric');

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
  const closePrices = d.map(x => x[1]);

  console.log("d");
  console.log(d);

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

  return {data:data, result:result};
  }
