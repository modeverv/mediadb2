var AppUtil = {
    isMsIE : /*@cc_on!@*/false,
    debug : function(s){
        //        console.log(s);
    },
    applyToSystem : function(){
        String.prototype.r = String.prototype.replace;
    }
};

var page = {
    /* manage selected */
    _selected_dirli_id : "",
    _selected_painli_id : "",
    chg_dirli_select : function(id){
        if(this._selected_dirli_id !== ""){
            $('#dirli-' + this._selected_dirli_id ).removeClass('selected');
        }
        $('#dirli-' + id ).addClass('selected');
        this._selected_dirli_id = id;
    },
    chg_painli_select : function(id){
        if(this._selected_painli_id !== ""){
            $('#painli-' + this._selected_painli_id ).removeClass('selected');
        }
        $('#painli-' + id ).addClass('selected');
        this._selected_painli_id = id;
    },
    /* make page */
    emitdirs : function(json){
        json = eval(json);

        // set window title and echo area
        if(page._selected_dirli_id === ""){
            $("#echoarea").html('');
        }
        // make page
        $("#side").html('');
        var elems = [];
        for(var i=0;i<json.length;i++){
            var elem = "<li id='dirli-" + json[i]['_id'] ;
            elem+= "' onclick='reload_dir(\""+ json[i]['_id'] +"\");return false;'>";
            elem += json[i]['name'];
            elem += "</li>";
            elem = $(elem);
            page._set_mover_css2elem(elem,'highlight');
            elems.push(elem);
        }
        var html = $("<ul></ul>");
        for(var i=0;i<elems.length;i++){
            html.append(elems[i]); 
        }
        $("#side").append(html);

        // ui
        if(page._selected_dirli_id !== ""){
            $('#dirli-' + page._selected_dirli_id ).toggleClass('selected');
        }
        $('#grayout').toggle();

        delete json;
    },
    emitdir : function(json){
        json = eval(json);
        // set window title and echo area
        if($('#query').val() !=''){
            var title = "::search::" + $('#query').val().split(' ').join('&').slice(0,20)  + '('+ json.length + ')';
            title += page._m3u_all_button('search','');
            if(!AppUtil.isMsIE)
                $('title').html("mediadb2::search::" + $('#query').val().split(' ').join('&') + '('+ json.length + ')' );
            var kind = "qs";
            var finder = $("#query").val();
            var ids = $("#query").val();
        }else{
            if(json.length > 0){
                var title = "::dir::" + json[0]['path'].replace(/^.*\/(.*)\/.*$/,"$1").slice(0,20) + "(" + json.length + ")" ;
                title += page._m3u_all_button('dir',page._selected_dirli_id);
                if(!AppUtil.isMsIE)
                    $('title').html("mediadb2::dir::" + json[0]['path'].replace(/^.*\/(.*)\/.*$/,"$1") + "(" + json.length + ")") ;
            }
            var kind = "dir";
            var finder = page._selected_dirli_id;
            var ids = page._selected_dirli_id;
        }
        $("#echoarea").html(title);

        // make page
        $("#pain").html('');
        var elems = [];
        for(var i=0;i<json.length;i++){
            // build html string
            var elem = "<li id='painli-" + json[i]['_id'] ;
            elem   += "'>";
            var img = "<img src='#{src}' alt='#{alt}'>";
            img = img.replace('#{alt}',json[i]['name']);
            if(json[i]['thumb_s'])
                img = img.replace('#{src}', "data:image/jpeg;base64," + json[i]['thumb_s'].str);
            elem += img;
            elem += "<span class='s_info'>";
            elem += "<span class='s_name_e'>" + json[i]['name'] + "</span>";
            elem += "<span class='s_info_e'>";
            elem += "video_codec:" + json[i]['video_codec'] + " ";
            elem += "audio_codec:" + json[i]['audio_codic'] + " ";
            elem += "resolution:"  + json[i]['resolution']  + " ";
            elem += "bitrate:"     + json[i]['bitrate'] + " ";
            elem += "duration:"    + json[i]['duration'] + " ";
            elem += "size:"        + json[i]['size'] + " ";
            elem += "path:"        + json[i]['path'] + " ";
            elem += "</span>";
            elem += "<span class='s_status_e'>Now Playing</span>";
            elem += page._file_page_button(json[i]['_id'],json[i]['name']);
            elem += page._file_get_button(json[i]['_id']);
            //            elem += page._file_button(json[i]['_id']);
            elem += "</span>";
            elem += "</li>";
            elem = $(elem);
            page._set_mover_css2elem(elem,'highlight');
            elems.push(elem);
        }

        var html = $("<ul>");
        for(var i=0;i<elems.length;i++){
            html.append(elems[i]); 
        }
        stateHandle({kind:kind,id:ids,finder:finder},"?"+kind+"="+finder);
        $("#pain").append(html);
        // ui
        $('#grayout').toggle();

        delete json;
    },
    /* private helper */
    _set_mover_css2elem : function(elem, cstr ) {
        elem.mouseover(function(){$(this).toggleClass(cstr);});
        elem.mouseout(function(){$(this).toggleClass(cstr);});
    },
    _m3u_all_button : function(kind,id){
        var elem = "<input type=\"button\" style='float:right;'class='submit_button' onclick=\"m3u_all('#{kind}','#{id}');return false;\" value=\"m3u_all\">";
        elem = elem.replace('#{kind}',kind).replace('#{id}',id);
        return elem;
    },
    _file_get_button : function(id){
        var elem = "<span class='s_button_e'><input type=\"button\" class='submit_button' onclick=\"getm3u('#{id}');return false;\" value=\"m3u\"></span>";
        elem = elem.replace('#{id}',id);
        return elem;
    },
    _file_page_button : function(id,name){
        var elem = "<span class='s_button_e'><a class='submit_button' href=\"/mediadb2/vlc/#{id}\" target='_blank' >view</a></span>";
        elem = elem.replace('#{id}',id + "/" + encodeURI(name));
        return elem;
    },
    _file_button : function(id){
        var elem = "<span class='s_button_e'><a style='float:right;' class='submit_button' href=\"/mediadb2/api/#{id}\" target='_blank'>vlc</a></span>";
        elem = elem.replace('#{id}',id);
        return elem;
    }

};
function getm3u(id){
    page.chg_painli_select(id);
    setTimeout(function(){
                   $('#painli-' + this._selected_painli_id ).fadeOut(200,
                                                                     function(){
                                                                         $('#painli-' + this._selected_painli_id ).removeClass('selected');
                                                                         $('#painli-' + this._selected_painli_id ).fadeIn(200);
                                                                     });
               },200);
    var api = server._prefix +"/"+ id + "/m3u";
    location.href = api;
    return false;

}
function m3u_all(kind,id){
    if(kind == 'search'){
        var api = server._prefix + "/search/m3u?t=" + (new Date())/1 + "&qs=" + $("#query").val();// + '&transcode=transcode';
    }else if(kind == "dir"){
        var api = server._prefix + "/dir/" + id + "/m3u";// + "?transcode=transcode";
    }else{
        return false;
    }
//http://192.168.110.7/mediadb2/api/search/m3u?t=1320140936183&qs=recent
    $("#pain").find('li').each(function(){
                                   $(this).addClass('selected');
                                   $(this).fadeOut(1000);
                                   var _this = this;
                                   setTimeout(function(){ $(_this).fadeIn(1000); },1001);
                                   setTimeout(function(){ $(_this).removeClass('selected'); },1500);
                               });
    page._selected_painli_id = "";
    location.href = api;
    return false;
}

// reload dirs
function reload_dirs(){
    $('#grayout').toggle();
    server.dirs();
    return false;
}
// do search
function run(){
    var qstring = $('#query').val();
    if(qstring=='') return false;
    $('#grayout').toggle();
    server.search(qstring);
    page.chg_dirli_select("");
    return false;
}
// reload dir
function reload_dir(id){
    $('#grayout').toggle();
    $('#query').val('');
    page.chg_dirli_select(id);
    server.dir(id);
    return false;
}

////////////////////////////////////////////////////
// init

/* push state */
var stateDryRun = false;
function stateHandle(obj,path){
    if(!AppUtil.isMsIE){
        if(stateDryRun){
            stateDryRun = false;
        }else{
            history.pushState(obj,"",path);
        }
    }
}

function popStateHandler(e) {
    // revive from state object
    if(e.state){
        if(e.state.kind=="qs"){
            stateDryRun = true;
            $('#query').val(e.state.id);
            run();
        }
        if(e.state.kind=="dir"){
            stateDryRun = true;
            page.chg_dirli_select(e.state.id);
            reload_dir(e.state.id);
        }
    }
}

function revive(location){
    // revive from requested uri
    if(location.search.match(/\?qs\=/)){
        stateDryRun = true;
        var qstring = location.search.replace('?qs=','');
        $('#query').val(qstring);
        run();
    }else if(location.search.match(/^\?dir\=/)){
        stateDryRun = true;
        var dirstring = location.search.replace('?dir=','');
        page.chg_dirli_select(dirstring);
        debug(dirstring);
        reload_dir(dirstring);
    }else{
        stateDryRun = true;
        $('#query').val('recent');
        run();
    }
}


$(function(){
      revive(location);
      server.init();
  });

$(function(){
      if (window.history && window.history.pushState) {
          $(window).bind("popstate", function(e){
                             popStateHandler(e.originalEvent);
                         });
      }
  });

