#! /home/seijiro/.rvm/rubies/ruby-1.9.2-p290/bin/ruby
# -*- coding:utf-8 -*-
require 'sinatra'
#require 'sinatra-xsendfile'
#=begin
module Sinatra
  module Xsendfile
    def x_send_file(path, opts = {})
      if opts[:type] or not response['Content-Type']
        content_type(opts[:type] || File.extname(path) || 'application/octet-stream')
      end

      if opts[:disposition] == 'attachment' || opts[:filename]
        attachment opts[:filename] || path
      elsif opts[:disposition] == 'inline'
        response['Content-Disposition'] = 'inline'
      end

      header_key = opts[:header] || (settings.respond_to?(:xsf_header) && settings.xsf_header) || 'X-SendFile'
      
#       path = File.expand_path(path).gsub(settings.public, '') if header_key == 'X-Accel-Redirect'
      puts path
      response[header_key] = path

      halt
    rescue Errno::ENOENT
      not_found
    end

    def self.replace_send_file!
      Sinatra::Helpers.send(:alias_method, :old_send_file, :send_file)
      Sinatra::Helpers.module_eval("def send_file(path, opts={}); x_send_file(path, opts); end;")
    end
  end

  helpers Xsendfile
end
#=end
#require "sinatra/reloader" #if development?
require File.dirname(__FILE__)+'/mediamodels'
#load File.dirname(__FILE__)+'/mediamodels.rb'
require 'tempfile'

configure :production do
#  Sinatra::Xsendfile.replace_send_file! #replaces sinatra's send_file with x_send_file
#  set :xsf_header, 'X-Accel-Redirect' #setting default(X-SendFile) header (nginx)
end

def get_prefix
  prefix = ""
#  prefix = "/mediadb2"
  prefix
end

### need modify via environment #############
helpers do 

  def prefix
    "/mediadb2"
  end
  
  def search(query)
    qs = query.split(' ').map {|q| /#{q}/i}
    Mediamodel.where(:search.all => qs).limit(1000).asc(:name).to_a
  end

  def feeling_lucky(query)
    allcount = Mediamodel.all.count
    feeling_lucky = rand(allcount)
    Mediamodel.skip(feeling_lucky).limit(10).asc(:name).to_a
  end

  def recent(query)
    Mediamodel.desc(:created_at).limit(50).to_a
  end

  def make_m3u_elem ret
    str = ""
    ret_title = ret.name

    #send_file
#    str += "#EXTINF:#{ret.duration.to_i},S#{ret_title} - #{ret_title}\n"
#    str += "http://#{request.host}#{prefix}/api/stream2/#{ret.id}/file#{File.extname ret.path}\n"

    #direct send_file
#    str += "#EXTINF:#{ret.duration.to_i},DS#{ret_title} - #{ret_title}\n"
#    str += "http://#{request.host}:8080#{prefix}/api/stream2/#{ret.id}/file#{File.extname ret.path}\n"

    
    #x_send_file
#    str += "#EXTINF:#{ret.duration.to_i},#{ret_title} - #{ret_title}\n"
#    str += "http://#{request.host}#{prefix}/api/stream/#{ret.id}/file#{File.extname ret.path}\n"

    #direct x_send_file
#    str += "#EXTINF:#{ret.duration.to_i},DX#{ret_title} - #{ret_title}\n"
#    str += "http://#{request.host}:8080#{prefix}/api/stream/#{ret.id}/file#{File.extname ret.path}\n"

    #ngix => node    
    str += "#EXTINF:#{ret.duration.to_i},N#{ret_title} - #{ret_title}\n"
    str += "http://#{request.host}/stream/mediadb2/#{ret.id}/file#{File.extname ret.path}\n"

    #node 
#    str += "#EXTINF:N#{ret.duration.to_i},DN#{ret_title} - #{ret_title}\n"
#    str += "http://#{request.host}:23001/stream/mediadb2/#{ret.id}/file#{File.extname ret.path}"

    str += "\n"  
  end

  def get_tmpfile(&block)
    path = nil
    tmp = Tempfile.open(['tm2','m3u'],'/tmp') do |io|
      io.puts "#EXTM3U"
      io.puts yield
      path = io.path
    end
    path  
  end

  def protected!
    unless authorized?
      response['WWW-Authenticate'] = %(Basic realm="mediadb2 Restricted Area")
      throw(:halt, [401, "Not authorized\n"])
    end
  end

  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == ['seijiro', 'hoge']
  end
  
end

### API #####################
get "#{get_prefix}/api/dirs" do
  expires 0 ,:public
  cache_control :public, 0
  rets = Dirmodel.all.asc(:name)
  if rets.first.nil?
    "error"
  else
    ret = []
    rets.each do |dir|
      elem = {}
      elem[:_id] = dir.id;
      elem[:path] = dir.path;
      elem[:name] = "#{dir.name}(#{dir.models_count})"
      ret << elem
    end
    content_type  'application/json; charset=utf-8'    
    ret.to_json
  end
end

get "#{get_prefix}/api/search" do
  content_type  'application/json; charset=utf-8'
  
  if params['qs'] == 'FeelingLucky'
    feeling_lucky(params['qs']).to_json
  elsif params['qs'].downcase == 'recent'
    recent(params['qs']).to_json
  else
    search(params['qs']).to_json
  end
end

get "#{get_prefix}/api/search/m3u" do
  puts params['qs']
  if params['qs'] == 'FeelingLucky'
    rets = feeling_lucky(params['qs'])
  elsif params['qs'].downcase == 'recent'
    rets = recent(params['qs'])
  else
    rets = search(params['qs'])
  end
  path = get_tmpfile do
    str = ""
    rets.each { |ret| str += make_m3u_elem ret }
    str
  end
  send_file path, :type => 'audio/x-mpegurl'
end

get "#{get_prefix}/api/dir/:mid*" do
  cache_control :public, :max_age => 60* 60 * 2
  
  ret = Dirmodel.where(:_id => params['mid']).first
  medias = ret.mediamodels.asc(:name)
  if medias
    content_type  'application/json; charset=utf-8'    
    medias.to_json
  else
    "error"
  end
end

get "#{get_prefix}/api/dir/:mid/m3u*" do
  ret = Dirmodel.where(:_id => params['mid']).first
  medias = ret.mediamodels
  if medias
    path = get_tmpfile do
      str = ""
      medias.each { |ret| str += make_m3u_elem ret }
      str
    end
    send_file path, :type => 'audio/x-mpegurl'
  else
    "error"
  end
end

get "#{get_prefix}/api/:mediaid/m3u" do
  ret = Mediamodel.find(params[:mediaid])
  if ret
    path = get_tmpfile { make_m3u_elem ret }
    send_file path, :type => 'audio/x-mpegurl'
  else
    "error"
  end
end

get "#{get_prefix}/api/stream/:mediaid/*" do
  protected!
  ret = Mediamodel.find(params[:mediaid])
  if ret
    x_send_file ret.path,:type => "video/#{File.extname(ret.path).gsub('.','')}"  else
    "error"
  end
end

get "#{get_prefix}/api/stream2/:mediaid/*" do
    protected!
  ret = Mediamodel.find(params[:mediaid])
  puts ret.path
  if ret
    x_send_file ret.path
  else
    "error"
  end
end


### page ####################
get "#{get_prefix}/" do
  protected!
  @prefix = get_prefix
  @config = "sinatra.js"
  expires 36000000 ,:public
  cache_control :public, 360000
  erb :index
end

get "#{get_prefix}/websocketversion" do
    protected!
  @prefix = get_prefix
  @config = "websocket.js"
  erb :index
end

get "#{get_prefix}/vlc/:mediaid/*" do
  protected!
  @mediaid = "http://#{request.host}#{get_prefix}/api/#{params[:mediaid]}"
  expires 36000 ,:public
  cache_control :public, 36000
  
  begin
    @media = Mediamodel.find(params[:mediaid])
  rescue
    @media = Mediamodel.first
  end
  erb :vlc
end


##########  manage  ###########################################
get "#{get_prefix}/manage" do
  protected!
  ret = ["<h1>manage</h1>"]
  place_folder = "<li><a href='#href#' target='_blank'>#link#</a>"
  ret << place_folder.gsub("#href#","/mediadb2/manage/update_db").gsub("#link#",'update_db')
end

get "#{get_prefix}/manage/update_db" do
  protected!
  ret = ["<h1>DONE:manage/update_db</h1>"]
  ret << Mediamodel.update_db
  ret.join(
"<br/>>")
end
##########  /manage  ###########################################

__END__

