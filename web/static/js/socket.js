"use strict"


import {Socket} from "phoenix"


//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//Phoenix socket setup
let socket = new Socket("/socket", {params: {token: window.userToken}})

socket.connect()

let channel = socket.channel("rooms:lobby", {})


channel.on("save_data",
  payload => {
    //send ok or error back
    console.log("payload");
    console.log(payload);
    }
  )

channel.on("new_msg",
  payload => {
    const {token: token, response_text: response_text, action: action, fullname: fullname} = payload.body;
    const message = {token: token, response: response_text, fullname: fullname};

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

//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//Elm setup

const initMesssage = {token: "", response: "", fullname: ""}

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
  const request = { action:"register", data: {username: u, password: p, fullname: f} }
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
//send to serverside
//save down
//

//loading other stuff is seperate
//new ui module which shows user's saved projects
//show latest projects with same parameters


//delete
//load
//new
const save = request =>
  {
  console.log(request);
  channel.push("save_data", {body: request});
  };

app.ports.saveToDB.subscribe(save);

//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

export default socket

//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//add new component
//list all stored charts - except the one that's currently being edited
//
//save all the info coming
