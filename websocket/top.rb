# -*- coding:utf-8 -*-
#require 'lib/em-websocket'
require 'em-websocket'

EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 8081, :debug => true) do |ws|
  ws.onopen {
    ws.send "Hello"
    ws.send `ls -la`
  }
  ws.onmessage { |msg|
    ws.send `top -b -n 1` if msg == "top"
    ws.send `vmstat` if msg == "vmstat"
    if msg == "file"
      buf = [File.open("/var/smb/sdb1/video/pv/中谷美紀 ／ クロニック・ラブ（「ケイゾク」主題歌）ＰＶ.flv.mp4" ,"rb").read].pack('m')
      ws.send buf
    end
  }
  ws.onclose { puts "WebSocket closed" }
  ws.onerror { |e| puts "Error: #{e.message}" }
end
