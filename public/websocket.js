// server
function debug(obj){
//    console.log(obj);
}

var socket = "hoge";
var server = {
    _ws : null,
    init : function(){
        debug("server:init");
        var Socket = "MozWebSocket" in window ? MozWebSocket : WebSocket;
        server._ws = new Socket(server._wsuri);
        socket = server._ws;

        server._ws.onmessage = function(evt) {
          debug("ws:onmessage:" + evt.data);
          if(evt.data.length > 20){
            debug("ws:onmessage:if");
              
             var json = eval(evt.data);
             var callback = json[0]['callback'];json.shift();
             var data = json;
             debug(callback);
             debug(data.length);
             eval("server." + callback + '(json)' );
          }
        };

        server._ws.onclose = function() { debug("socket closed"); };

        server._ws.onopen = function() {
          server._connected = true;
          debug("Connected.");
          reload_dirs();
        };
    },
    _connected : false,
    callback_api_dirs   : function(json){ 
          debug("callbacked");
          page.emitdirs(json);
    },
    callback_api_dir    : function(json){ page.emitdir(json); },
    callback_api_search : function(json){ page.emitdir(json);},
    search : function(qstring) {
        server._ws.send( "get:search:" + encodeURIComponent(qstring) );
    },
    dirs : function(){
        server._ws.send("get:dirs");
    },
    dir : function(id,retry){
        retry = retry ? 0 :1;
        if(server._connected){//TODO temporary
          server._ws.send( "get:dir:" + id );
        }else{
          //retry
          setTimeout(function(){
             if(retry > 2){
                 $("grayout").fadeOut(0);
                 debug("諦める");
             }else{
                 server.dir(id,retry + 1);
             }
          },100);
        }
    },
    m3u : function(id){
        this._server_get(id + "/m3u" ,"",page.emitdir);
    },
    _server_get : function(uri,pdata,callback){
        $.ajax({  
                   type: "GET",
                   url: this._prefix + "/" + uri ,
                   data: "qs="+pdata,
                   success: function(msg){
                       callback(msg);
                   },
                   error:function(msg){
                       $("#grayout").fadeIn(0);
                   }
               });    
    },
//    _prefix : "/api"
    _wsuri : "ws://192.168.110.7:8080/",
    _wsuri : "ws://" + location.host + ":8080/",
//    _prefix : "mediadb2/api",
    _prefix : "api"
};

console.log(server._wsuri);
console.log(server._wsuri);
function server_init(){
        debug("server:init");
        var Socket = "MozWebSocket" in window ? MozWebSocket : WebSocket;
        socket = new Socket(server._wsuri);
        socket.onmessage = function(evt) {
          debug("ws:onmessage:" + evt.data);
          if(evt.data.lenght > 20){
            debug("ws:onmessage:if");
              
             var json = eval(evt.data);
             var callback = json[0]['callback'];json.shift();
             var data = json;
             debug(callback);
             debug(data.length);
             eval("server." + callback + '(json)' );
          }
        };

        socket.onclose = function() { debug("socket closed"); };

        socket.onopen = function() {
          debug("Connected.");
          socket.send("Hello.");
//          socket.send("get:dirs");
        };
}

