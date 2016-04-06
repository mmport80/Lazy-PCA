"use strict"


import {Socket} from "phoenix"

//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//Phoenix socket setup
let socket = new Socket("/socket", {params: {token: window.userToken}})

socket.connect()

let channel = socket.channel("rooms:lobby", {})

channel.join()
  .receive("ok", resp => { console.log("Joined successfully", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })


//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//Receive data from server and send to Elm code

channel.on("save_data",
  payload => {
    payload.body.plots.length === 0 ?
      console.log( payload.body.response_text )
      :
      app.ports.newPlotResponse.send( payload.body.plots[0] );
    }
  )

//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
channel.on("delete_data",
  payload => {
    //receive ok or error
    console.log("delete response");
    console.log(payload);
    }
  )

//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//change new_msg to something more meaningful
//reg & login responses from server
channel.on("new_msg",
  payload => {
    const {token: token, response_text: response_text, action: action, fullname: fullname, plots: plots} = payload.body;

    //convert plots to elm format
    const elmPlots = plots.map(
      p =>
        ({endDate:p.endDate, startDate: p.startDate, ticker:p.ticker, y:p.y, source:p.source, frequency:p.frequency, id:p.id})
      );

    const loginResponse = {token: token, response: response_text, fullname: fullname, plots: elmPlots};
    const registerResponse = {token: token, response: response_text, fullname: fullname};

    action === "login" ?
      app.ports.loginResponse.send(loginResponse)
      : (action === "register" ?
        app.ports.registerResponse.send(registerResponse)
        :
          null)
    }
  )

//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//Elm setup

const initPlot = {endDate:"", startDate:"", ticker:"", y:false, source:"", frequency:21, id:-1};

const initLogRegResponse = {token: "", response: "", fullname: ""
  , plots: [
      {endDate:"", startDate:"", ticker:"", y:false, source:"", frequency:21, id:-1}
    ]
  }

const div = document.getElementById('elm');
const app = Elm.embed(
    Elm.Main
  , div
  , {
      loginResponse: initLogRegResponse
    , registerResponse: initLogRegResponse
    , newPlotResponse: initPlot
    }
  );


//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//push data from Elm up to server / UI

const registerCallback = msg => {
  //change fields, so that clientside and serverside match up
  const request = { action:"register", data: msg }
  channel.push("new_msg", {body: request})
  }

app.ports.registerRequest.subscribe(registerCallback);

//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

const loginCallback = msg => {
  const request = { action: "login", data:msg }
  channel.push("new_msg", {body: request})
  }

app.ports.loginRequest.subscribe(loginCallback);

//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

const draw = z =>
  {
  if (z.length > 1) {
    const {data:data,result:result} = elmProcessData(z);
    getScatterPlot(data,result);
    }
  else {
    console.log("Not enough data");
    }
  return null;
  };

app.ports.sendToScatterPlot.subscribe(draw);

//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

const save = request =>
  {
  channel.push("save_data", {body: request});
  }

app.ports.saveToDB.subscribe(save);

//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

const delete_ = request =>
  {
  channel.push("delete_data", {body: request});
  }

app.ports.deleteFromDB.subscribe(delete_);

//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

export default socket

//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
