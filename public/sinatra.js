function debug(obj){
//    console.log(obj);
}

// server
var server = {
    init :function(){
      reload_dirs();
    },
    search : function(qstring) {
        this._server_get('search',qstring,page.emitdir);
    },
    dirs : function(){
        this._server_get('dirs',"",page.emitdirs);
    },
    dir : function(id){
        this._server_get('dir/'+ id ,"",page.emitdir);
    },
    m3u : function(id){
        this._server_get(id + "/m3u" ,"",page.emitdir);
    },
    _server_get : function(uri,pdata,callback){
        var qdata = {
            qs : pdata
        };
        if(pdata == "recent")
           qdata.t = (new Date())/1;
        $.ajax({  
                   type: "GET",
                   url: this._prefix + "/" + uri ,
                   data: qdata,
                   success: function(msg){
                       callback(msg);
                   },
                   error:function(msg){
                       $("#grayout").fadeIn(0);
                   }
               });    
    },
//    _prefix : "/api"
    _prefix : "/mediadb2/api"
};
