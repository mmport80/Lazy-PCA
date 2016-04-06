# [Lazy PCA](http://23.251.138.83/)

A simple tool to see how asset returns evolve over time using Principal Components Analysis.

## Install

This is a Phoenix app which uses Elm for the frontend.

##Code of Interest

- See the front end's use of the Elm architecture [here](https://github.com/mmport80/Lazy-PCA/tree/elm-version/web/elm)

- The JavaScript glue between Elm and the Phoenix framework is [here](https://github.com/mmport80/Lazy-PCA/blob/elm-version/web/static/js/socket.js)

- Elixir code using Phoenix channels which interfaces with the database is [here](https://github.com/mmport80/Lazy-PCA/blob/elm-version/web/channels/room_channel.ex)
