# Stargate
A Fast Webserver written in Elixir and Erlang.

## Status
Currently, this is very much in alpha. I've taken the great work done by [**@van163**](https://github.com/vans163/stargate) as a starting point and inspiration, in order to build up a fast Webserver in pure Elixir.

I've fully rewritten the Elixir branch of @van163's work, cleaning it up, adding more Elixir structure and features to the project, splitting things into smaller and simpler functions, and adding proper functionalities to support various HTTP standards that the original server didn't support.

## Current Features
- Simple support for HTTP/1.1 and below (No HTTP/2.0 or HTTP/3.0 yet)
- SSL (by passing SSL options to the config, which are subsequently passed to the :ssl erlang underlying application)
- Websockets
  - Partially implemented, frames are not fully working yet since the parser is not completely implemented

## Roadmap/TODOS
- [x] Support for HTTP/1.1 and below.
  - [x] On HTTP/0.9 requests, we must close the connection on the server side after sending the response.
  - [x] On HTTP/1.0 requests, we must close the connection unless a "Connection: Keep-Alive" Header is received from the client and then subsequently sent by the server.
  - [x] On HTTP/1.1 requests, we only close the connection if a "Connection: Close" Header is received from the client, or if we send a "Connection: Close" Header from the server.
- [ ] Support for HTTP/2.0.
  - [ ] Read the HTTP/2.0 standards and RFCs in order to support it correctly
- [ ] Optimize the parsing of request data for fastest performance.
  - [x] Header Parsing and Searching
  - [ ] Body Parsing and Searching
- [x] Document how SSL options need to look in order to pass them through the configuration in the initial `Stargate.warp_in` function.
- [ ] Write out the full algorithm for parsing Websocket Frames.
  - As of now, the `Stargate.Vessel.Websocket.OldFrame` class is very rudimentary, I was able to somewhat figure it out with help from another project, but I still need to write out the full correct way of parsing frames in order to make the server fully websocket compliant.
  - [x] Make sure that Websocket handshake and websocket handling returns the correct values for `connection_state`.
  - [ ] Parsing Received Data Frames:
    - [x] Text
    - [ ] Binary
    - [ ] Ping
    - [ ] Continuation
    - [ ] Close
  - [ ] Generate Server Sent Data Frames:
    - [ ] Text
    - [ ] Binary
    - [ ] Pong
    - [ ] Continuation
    - [ ] Close
- [ ] Write macros for building simple APIs (similar to how Plug works for Cowboy)
  - Alternatively, write an adapter for Plug
- [ ] Create benchmarks on all aspects and write them out

## Credits

The main credit here goes to [**@van163**](https://github.com/vans163) for being frustrated with Elixir's standings in various benchmarks. After seeing his comments about this and his initial work, I decided to undertake this as a project in order to learn more about how web servers work and Elixir as a whole.

## License Remarks

@van163's original project was done under a GNU GPLv3 License. I initially forked his repository in order to have a copy of the code for inspiration and to help me if I was getting stuck anywhere, but I ended up simply writing my code in the same repository.

Since the entirety of the project is being written from scratch, and my intention was always (and still is) only to use @van163's work to help me understand how to write low level TCP code in Elixir and Erlang, I am going to be changing the license from the GNU GPLv3 License to my preferred MIT License.

If someone sees an issue with this and has a valid argument, please open an issue, and I will gladly change it back to the GNU GPLv3 if it's necessary.