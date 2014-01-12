class GlobServer
  include Enumerable

  attr_accessor :files
  
  def initialize(args = {})
    @folders = args[:folders] ||= [
                                   '/var/smb/sdb1/video',
                                   '/var/smb/sdb1/video2',
                                   '/var/smb/sdd1/transmission-daemon/downloads/video',
                                   '/var/smb/sdd1/video',
                                  ] 
    @ext = args[:ext] ||= [
                           'mp4','flv','wmv','mkv','mov','avi','m2ts',
                           'MP4','FLV','WMV','MKV','MOV','AVI',
                          ]
    @files = []
  end

  def media_glob
    @folders.each do |p|
      @ext.each do |e|
        Dir.glob("#{p}/**/*.#{e}") do |element|
          @files << {:path => element}
        end
      end
    end
  end

  def each
    @folders.each do |p|
      @ext.each do |e|
        Dir.glob("#{p}/**/*.#{e}") do |element|
          yield element
        end
      end
    end
  end
end
