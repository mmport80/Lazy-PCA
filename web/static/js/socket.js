"use strict"


import {Socket} from "phoenix"


//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//setup
let socket = new Socket("/socket", {params: {token: window.userToken}})

socket.connect()

let channel = socket.channel("rooms:lobby", {})

channel.on("new_msg",
  payload => {
    const {token: token, response_text: response_text, action: action} = payload.body;
    const message = {token: token, response: response_text};

    action === "login" ?
      app.ports.loginResponse.send(message)
    : (action === "register" ?
        app.ports.registerResponse.send(message)
      :
        null)
    }
  )

channel.join()
  .receive("ok", resp => { console.log("Joined successfully", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })

const initMesssage = {token: "", response: ""}

const div = document.getElementById('elm');
const app = Elm.embed(
    Elm.Main
  , div
  , {
      loginResponse: initMesssage
    , registerResponse: initMesssage
    }
  );

//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//push up to server

const registerCallback = msg => {
  //change fields, so that clientside and serverside match up
  const {username: u, password: p, fullname: f} = msg;
  const request = { action:"register", data: {username: u, password: p, name: f} }
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
  const {data:data,result:result} = elmProcessData(z);

  getScatterPlot(data,result);

  return null;
  };

app.ports.sendToScatterPlot.subscribe(draw);


//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


export default socket
