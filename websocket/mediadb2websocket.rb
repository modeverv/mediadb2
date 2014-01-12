# /usr/bin/env ruby
# -*- coding:utf-8 -*-
require 'em-websocket'
require File.join(File.dirname(__FILE__), '..','/',)+"mediamodels"
require 'cgi'
require 'kconv'

Process.daemon(nochdir=true) if ARGV[0] == "-D"

Mongoid.unit_of_work do

def api_dirs
  rets = Dirmodel.all
  if rets.first.nil?
    "error"
  else
    puts "mongoid dir ret exists"
    dirs = []
    rets.each do |dir|
      elem = {}
      elem[:_id] = dir.id;
      elem[:path] = dir.path;
      elem[:name] = "#{dir.name}(#{dir.models_count})"
      dirs << elem
    end
    ([{
        "method" => "api_dirs",
        "callback" => "callback_api_dirs",
      }
     ] + dirs).to_json.to_s
  end
end

def api_dir(mid)
  ret = Dirmodel.where(:_id => mid).first
  medias = ret.mediamodels
  if medias
    medias.each {|e| e.thumb_s = [e.thumb_s.to_s].pack('m')}
#    medias.to_json.to_s
    ([{
        "method" => "api_dir_#{mid}",
        "callback" => "callback_api_dir",
      }
     ] + medias).to_json.to_s
  else
    "error #{mid}"
  end
end

def api_search(querystring)
  query = CGI.unescape(querystring.toutf8)
  qs = query.split(' ').map {|q| /#{q}/i}
  medias = Mediamodel.where(:search.all => qs).limit(1000).to_a
  
  medias = medias.each {|e|e.thumb_s = [e.thumb_s.to_s].pack('m')}
  ([{
        "method" => "api_search_#{querystring}",
        "callback" => "callback_api_search",
      }
   ] + medias).to_json.to_s
end

EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 8080, :debug => true) do |ws|
  ws.onopen { ws.send "Hello Client!"}
  ws.onmessage { |msg|
#    ws.send "Pong: #{msg}"
    
    # dispacher
    if msg =~ /get:dirs$/
      ws.send api_dirs
    end
    if msg =~ /get:dir:(.+)$/
      ws.send api_dir $1
    end
    if msg =~ /get:search:(.+)$/ #need escape querystring
      ws.send api_search $1
    end
  }
  ws.onclose { puts "WebSocket closed" }
  ws.onerror { |e| puts "Error: #{e.message}" }
end
end
