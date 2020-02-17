%%%-------------------------------------------------------------------
%%% @author erlang
%%% @copyright (C) 2020, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 17. Feb 2020 10:56
%%%-------------------------------------------------------------------
-module(index_handlers).

-author("erlang").

-export([init/2, doc/0]).
%%-export([content_types_provided/2]).
-export([is_authorized2/1]).
%%-export([to_text/2]).

init(Req0, Opts) ->
  case is_authorized2(Req0) of
    ok ->
      Req = cowboy_req:stream_reply(200,#{<<"content-type">> => <<"text/html">>},
      Req0),cowboy_req:stream_body(doc(),fin,Req),
      {ok,Req,Opts};
    failed -> cowboy_req:reply(403, Req0),
      {ok,Req0,Opts}
  end.

is_authorized2(Req0)->
  Token = cowboy_req:header(<<"token">>, Req0),
  io:format("~w~s~n", [tokenTest,Token]),
  case Token of
    undefined -> failed;
    _ -> {Status, _Decoded } = jwt:decode(Token, <<"secret">>),
      case Status == ok of
        true ->  ok;
        false -> failed
      end
  end.

doc()->
 <<"<html>
<head>
    <meta http-equiv=\"Content-Type\" content=\"text/html; charset=ISO-8859-1\">
    <title>Mnesia observer</title>
    <script src=\"/static/jquery.min.js\"></script>
    <script type=\"text/javascript\">

      var websocket;
      $(document).ready(init);

      function init() {
          $('#server').val(\"ws://\" + window.location.host + \"/websocket\");
          if(!(\"WebSocket\" in window)){
              $('#status').append('<p><span style=\"color: red;\">websockets are not supported </span></p>');
              $(\"#navigation\").hide();
          } else {
              $('#status').append('<p><span style=\"color: green;\">websockets are supported </span></p>');
              connect();
          };
              $(\"#connected\").hide();
              $(\"#content\").hide();
      };

      function connect()
      {
          wsHost = $(\"#server\").val()
          websocket = new WebSocket(wsHost);
          showScreen('<b>Connecting to: ' +  wsHost + '</b>');
          websocket.onopen = function(evt) { onOpen(evt) };
          websocket.onclose = function(evt) { onClose(evt) };
          websocket.onmessage = function(evt) { onMessage(evt) };
          websocket.onerror = function(evt) { onError(evt) };
      };

      function disconnect() {
          websocket.close();
      };

      function toggle_connection(){
          if(websocket.readyState == websocket.OPEN){
              disconnect();
          } else {
              connect();
          };
      };

      function sendTxt() {
          if(websocket.readyState == websocket.OPEN){
              txt = $(\"#send_txt\").val();
              websocket.send(txt);
              showScreen('sending: ' + txt);
          } else {
               showScreen('websocket is not connected');
          };
      };

      function onOpen(evt) {
          showScreen('<span style=\"color: green;\">CONNECTED </span>');
          $(\"#connected\").fadeIn('slow');
          $(\"#content\").fadeIn('slow');
      };

      function onClose(evt) {
          showScreen('<span style=\"color: red;\">DISCONNECTED </span>');
      };

      function onMessage(evt) {
          showScreen('<span style=\"color: blue;\">RESPONSE: ' + evt.data+ '</span>');
      };

      function onError(evt) {
          showScreen('<span style=\"color: red;\">ERROR: ' + evt.data+ '</span>');
      };

      function showScreen(txt) {
          $('#output').prepend('<p>' + txt + '</p>');
      };

      function clearScreen()
      {
          $('#output').html("");
      };
    </script>
</head>

<body>
<div id=\"header\">
    <h1>Websocket client</h1>
    <div id=\"status\"></div>
</div>


<div id=\"navigation\">

    <p id=\"connecting\">
        <input type='text' id=\"server\" value=""></input>
        <button type=\"button\" onclick=\"toggle_connection()\">connection</button>
    </p>
    <div id=\"connected\">
        <p>
            <input type='text' id=\"send_txt\" value=></input>
            <button type=\"button\" onclick=\"sendTxt();\">send</button>
        </p>
    </div>

    <div id=\"content\">
        <button id=\"clear\" onclick=\"clearScreen()\" >Clear text</button>
        <div id=\"output\"></div>
    </div>

</div>
</body>
</html>">>.

%%is_authorized(Req0,State)->
%%  Token = cowboy_req:header(<<"Authorization">>, Req0),
%%  io:format("~w~w~n", [tokenTest,Token]),
%%  case Token of
%%    undefined -> {false,Req0,State};
%%    _ -> {Status, _Decoded } = jwt:decode(Token, <<"secret">>),
%%      case Status == ok of
%%        true ->  {true,Req0,State};
%%        false -> {false,Req0,State}
%%      end
%%  end.

%%content_types_provided(Req, State) ->
%%  {[
%%    {<<"text/plain">>, to_text}
%%  ], Req, State}.
%%
%%to_text(Req, User) ->
%%  {<< "Hello, ", User/binary, "!\n" >>, Req, User}.