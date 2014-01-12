#! /usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'mongo'
require 'mongoid'
require 'kconv'
require 'streamio-ffmpeg'


class Object
  def __bson_dump__(*args, &block)
    strategies =
      %w(
        to_bson
        to_mongo
        as_document
        to_hash
      )

    strategies.each do |strategy|
      if respond_to?(:strategy)
        converted = send(:strategy)

        if converted.respond_to?(:__bson_dump__)
          return converted.send(:__bson_dump__, *args, &block)
        end
      end
    end

    e = NoMethodError.new('__bson_dump__')
    e.set_backtrace(caller)
    raise(e)
  end
end

# https://github.com/streamio/streamio-ffmpeg/blob/025a935e90b45b366fcd2d6d4cc68b560a478104/README.md

# Mongoid.load!( File.dirname(__FILE__) + "/mongoid.yml")

Mongoid.configure do |config|
##  config.master = Mongo::Connection.new('192.168.110.7').db('media-mongoid4')
  config.master = Mongo::Connection.new('localhost').db('mediadb2-mongoid')
#  config.identity_map_enabled = true
end
#
class Dirmodel
  include Mongoid::Document
  field :path, type: String, :default => ''
  field :name, type: String, :default => ''
  field :created_at, :type => DateTime, :default => Time.now
  field :count_data, type:Integer
  
#  index :path
  
  has_and_belongs_to_many :mediamodels

  def models_count
    unless self.count_data
      self.count_data = self.mediamodels.size
      self.save
    end
    self.count_data    
  end

  def self.update_db
    Dirmodel.all.each do |e|
      print "#{e.name} - #{e.models_count} -> "
      e.count_data = e.mediamodels.size
      print "#{e.count_data}\n"
      if e.count_data == 0
        e.delete
      else
        e.save
      end
    end
  end
end

class Mediamodel
  include Mongoid::Document

  before_save :set_search
  
  field :name, type: String, :default => ''
  field :path, type: String, :default => ''
  field :thumb_s, :type => BSON::Binary
  field :thumb_m, :type => BSON::Binary
  field :search, type: String, :default => ''
  field :created_at, :type => DateTime, :default => Time.now

  field :duration, type: String, :default => ''
  field :bitrate, type: String, :default => ''
  field :size , type: String, :default => ''
  field :video_stream , type: String, :default => ''
  field :video_codec, type: String, :default => ''
  field :colorspace , type: String, :default => ''
  field :resolution , type: String, :default => ''
  field :width , type: String, :default => ''
  field :height, type: String, :default => ''
  field :frame_rate , type: String, :default => ''
  field :audio_stream , type: String, :default => ''
  field :audio_codic, type: String, :default => ''
  field :audio_sample_rate , type: String, :default => ''
  field :audio_channels , type: String, :default => ''
  
#  index :search
#  index :path

  has_and_belongs_to_many :dirmodels

  def set_search
    self.search = "#{path}|#{duration}|#{bitrate}|#{size}|#{video_stream}|#{video_codec}|#{colorspace}|#{resolution}|#{width}|#{height}|#{frame_rate}|#{audio_stream}|#{audio_codic}|#{audio_sample_rate}|#{audio_channels}"
  end
  
  class << self
    def update_db
      delete_not_exist_entry
      
      ret = [] 
      require File.dirname(__FILE__)+'/globmodel'
      gs = GlobServer.new

      gs.each do |e|
        puts e
        unless Mediamodel.where(:path => e).first.nil?
          next
        end
        Mediamodel.path2object(e)
      end

      Dirmodel.update_db
      
    end

    def delete_not_exist_entry
      rets = Mediamodel.all
      rets.each do |media|
        puts "check #{media.id} => #{media.path}"
        if !File.exists?(media.path)
          puts " not_exist => #{media.path}" 
          dir = media.dirmodels.first
          dir.mediamodels.delete media
          media.delete
        end
      end
    end
    
    def path2object(path)
      p path
      _dir = File.dirname(path)
      dir = Dirmodel.where(:path => _dir).first
      if dir.nil?
        dir = Dirmodel.new(:path => _dir,:name => File.basename(_dir))
        dir.save
      end
      
      movie = FFMPEG::Movie.new(path)
      model = Mediamodel.new(
                             :path => path,
                             :name => File.basename(path),
                             )

      dir.mediamodels <<  model
      dir.save      
      
      begin;model.duration       = movie.duration       ;rescue => ex;p ex;end
      begin;model.bitrate        = movie.bitrate        ;rescue => ex;p ex;end
      begin;model.size           = movie.size           ;rescue => ex;p ex;end
      begin;model.video_stream   = movie.video_stream   ;rescue => ex;p ex;end
      begin;model.video_codec    = movie.video_codec    ;rescue => ex;p ex;end
      begin;model.colorspace     = movie.colorspace     ;rescue => ex;p ex;end
      begin;model.resolution     = movie.resolution     ;rescue => ex;p ex;end
      begin;model.width          = movie.width          ;rescue => ex;p ex;end
      begin;model.height         = movie.height         ;rescue => ex;p ex;end
      begin;model.frame_rate     = movie.frame_rate     ;rescue => ex;p ex;end
      begin;model.audio_stream   = movie.audio_stream   ;rescue => ex;p ex;end
      begin;model.audio_codic    = movie.audio_codec    ;rescue => ex;p ex;end
      begin;model.audio_channels =  movie.audio_channels;rescue => ex;p ex;end
      begin;model.audio_sample_rate =  movie.audio_sample_rate ;rescue => ex;p ex;end
  
      begin
        #thumnail取得
        buff_s = `ffmpeg -itsoffset 4 -i "#{path}" -f image2 -vframes 1 -ss 1 -s 320x240 -an -deinterlace -`
        model.thumb_s = BSON::Binary.new [buff_s].pack('m')
      rescue =>ex
        puts "thumbnail ex"
        puts ex
      end
      
      model.save
    rescue =>exx
      puts exx
    end
  end
end
