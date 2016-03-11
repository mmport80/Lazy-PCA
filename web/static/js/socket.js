// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "web/static/js/app.js".

// To use Phoenix channels, the first step is to import Socket
// and connect at the socket path in "lib/my_app/endpoint.ex":
import {Socket} from "phoenix"

let socket = new Socket("/socket", {params: {token: window.userToken}})


socket.connect()

// Now that you are connected, you can join channels with a topic:
let channel = socket.channel("rooms:lobby", {})
let messagesContainer = $("#messages")

channel.on("new_msg", payload => {
  //messagesContainer.append(`<br/>[${Date()}] ${payload.body}`)
  console.log(payload.body);
  app.ports.loginResponse.send("111111111111111111111")
})

channel.join()
  .receive("ok", resp => { console.log("Joined successfully", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })

//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
//push up to server
function testPortCallback(val) {
  const {username: u, password: p, response: _} = val;


  const exampleUser = {action:"login",data:{username: u, password: p, name: "john"}}
  channel.push("new_msg", {body: exampleUser})
  }

const div = document.getElementById('stamper');
const app = Elm.embed(Elm.Main, div, {loginResponse: ""});

//one port for each action
//Login
//Registration

app.ports.loginRequest.subscribe(testPortCallback);


//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

export default socket
