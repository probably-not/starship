# Stargate
A Fast Webserver written in Elixir and Erlang.

## Status
Currently, this is very much in alpha. I've taken the great work done by [**@van163**](https://github.com/vans163) and am cleaning it up a bit by adding more Elixir structure to the project, so that it can be easily used by everyone.

## Current Features
- Simple support for HTTP (No HTTP/2 or HTTP/3 yet)
- SSL (by passing SSL options to the config, which are subsequently passed to the :ssl erlang underlying application)
- Websockets
  - Partially implemented, frames are not fully working yet since the parser is not completely implemented

## TODOS
- Connections are not being closed correctly even when a server sends a "Connection: Close" Header.
  This causes tools like Apache Bench to fail with timeouts, since they are waiting for a connection that is still alive even after a response is sent.
  - According to standards:
    - [x] On HTTP/0.9 requests, we must close the connection on the server side after sending the response.
    - [x] On HTTP/1.0 requests, we must close the connection unless a "Connection: Keep-Alive" Header is received from the client and then subsequently sent by the server.
    - [x] On HTTP/1.1 requests, we only close the connection if a "Connection: Close" Header is received from the client, or if we send a "Connection: Close" Header from the server.