require 'sinatra/reloader'
require 'sinatra/json'
require 'sinatra/content_for'
require_relative 'lib/rack/flash'
require_relative 'lib/core_ext/hash'
require_relative 'helpers/sinatra'
require_relative 'models/track'
require 'taglib'
require 'pathname'
require 'json'

# disable running by default, otherwise just requiring it would trigger a duplicate
set :run, false

class CoffeeHandler < Sinatra::Base
  set :views, File.dirname(__FILE__) + '/templates/coffeescripts'
  
  get "/coffeescripts/*.coffee" do
    filename = params[:splat].first
    coffee filename.to_sym
  end
end

class Sinatra::Request
  def pjax?
    env['HTTP_X_PJAX'] || self['_pjax']
  end
end

class WebInterface < Sinatra::Base
  register Sinatra::Reloader
  register Sinatra::Async
  also_reload "helpers/*.rb"
  also_reload "models/*.rb"
  
  helpers Sinatra::ContentFor
  helpers Sinatra::JSON
  helpers WebHelpers

  use CoffeeHandler
  use Rack::Session::Cookie, :secret => 'onelovemang'
  use Rack::MethodOverride
  use Rack::Flash

  set :root, File.dirname(__FILE__)

  def generate_coverspan tracks
    result = [] << 1 # add 1 for first entry
    tracks.each_cons(2) do |track, next_track|
      track.album == next_track.album ? result[-1] += 1 : result << 1
    end
    return result
  end

  def relative_to path
    Pathname.new(path).relative_path_from(Pathname.new(settings.public_folder)).to_s
  end

  get '/' do
    if !request.pjax?
      slim :index
    else
      pjax_partial :index
    end
  end

  get '/test' do
    Tagger.generate_db self
  end

  get '/clear' do
    Track.delete_all
  end

  apost '/ajax/search' do
    # if string is empty, return all tracks instead of searching for it, speed optimization
    tracks = params[:query].blank? ? Track.sort(:album, :track).all : Track.where(:$or => [
      {:album => /#{params[:query]}/i},
      {:artist => /#{params[:query]}/i},
      {:title => /#{params[:query]}/i},
      ]).sort(:album, :track).all
    body partial :tracklist, :locals => {:tracks => tracks}
  end

  apost '/ajax/edit-modal' do
    if params[:query].length == 1 # single track edit
      body partial :single_edit, :locals => {:query => params[:query], :track => Track.find(params[:query].first)}
    else
      result = {}
      placeholder = {:artist => [], :year =>[], :total_tracks => [], :disc => [], :total_discs => [], :albumartist => [], :album => [], :genre => [], :bpm => []}
      Track.find(params[:query]).each {|track| 
        placeholder.each_pair {|key, value| value << track.send(key)}
      }
      placeholder.each_pair {|key, arry| arry.uniq!; result[key] = arry.length == 1 ?  arry.first : nil}
      body partial :multi, :locals => {:query => params[:query] , :track => result}
    end
  end

  post '/ajax/edit' do
    tag = params[:tag]
    ids = JSON.parse(tag.delete 'id') # parse the stringified ID array

    if ids.length > 1
      tag.delete_keys 'title' # delete per-track specific title
      # delete any keys that aren't checkmarked
      tag.delete_if {|key, value| !(params[:check].include? key) }
    end

    ids.each {|id| 
      track = Track.find(id)
      track.update_attributes! tag
      Tagger.write_tags track
    }
    body params[:check].inspect
  end

  apost '/ajax/track' do
    body json :track => URI.escape(Track.find(params[:track_id]).filename)
  end

  aget '/ajax/track/:id' do
    if params[:id] != "undefined"
      track = Track.find params[:id]
      if track
        body json :album => track.album,:artist => track.artist,:title => track.title, :cover => track.cover
      else
        body json :title => "Track not found."
      end
    else
      body json :album => "Unknown", :artist => "Unknown", :title => "No song", :cover => "blank.png"
    end
  end

  # pjax calls
  aget '/player' do
    body partial :player
  end

end

#---------------------------------

class Tagger
  def self.generate_db sinatra
    files = Dir["#{File.dirname(__FILE__)}/public/music/**/*.mp3"]
    files.each {|filename|
      file = TagLib::MPEG::File.new filename
      tag = file.id3v2_tag
      old_tag = file.id3v1_tag

      disc = tag.frame_list('TPOS').first 
      disc = disc ? disc.to_s.split('/') : [nil, nil]

      t = Track.new(
        :title => tag.title || old_tag.title || File.basename(filename).gsub(/\.mp3\z/, ''),
        :artist => tag.artist || old_tag.artist,
        :album => tag.album || old_tag.album,
        :year => tag.year || old_tag.year,
        :track => tag.track || old_tag.track,
        :time => file.audio_properties.length,
        :disc => disc[0],
        :albumartist => tag.frame_list('TPE2').first,
        :total_tracks => tag.frame_list('TRCK').first.to_s.split('/')[1],
        :total_discs => disc[1],
        :genre => tag.genre || old_tag.genre,
        #:rating => ,
        :bpm => tag.frame_list('TBPM').first,
      )
      t.filename = sinatra.relative_to filename
      t.save!
    }
  end

  def self.write_tags track
    # Load an ID3v2 tag from a file
    TagLib::MPEG::File.open("public/#{track.filename}") do |file|
      tag = file.id3v2_tag

      tag.title = track.title
      tag.artist = track.artist
      tag.album = track.album
      tag.year = track.year.to_i
      tag.genre = track.genre
      # track count
      if track.total_tracks and track.track
        tag.frame_list('TRCK').first.text = "#{track.track}/#{track.total_tracks}"
      elsif tag.track
        tag.track = track.track.to_i
      end
      # add album artist
      if track.albumartist
        tag.add_frame TagLib::ID3v2::TextIdentificationFrame.new('TPE2',TagLib::String::UTF8) if tag.frame_list('TPE2').empty?
        tag.frame_list('TPE2').first.text = track.albumartist
      end
      # add disc
      if track.disc
        tag.add_frame TagLib::ID3v2::TextIdentificationFrame.new('TPOS',TagLib::String::UTF8) if tag.frame_list('TPOS').empty?
        disc = track.disc.to_s
        disc << "/#{track.total_discs}" if track.total_discs
        tag.frame_list('TPOS').first.text = disc
      end
      # bpm
      if track.bpm
        tag.add_frame TagLib::ID3v2::TextIdentificationFrame.new('TBPM',TagLib::String::UTF8) if tag.frame_list('TBPM').empty?
        tag.frame_list('TBPM').first.text = track.bpm.to_s
      end

      file.save
    end
  end
end