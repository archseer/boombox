require 'sinatra/reloader'
require 'sinatra/json'
require 'sinatra/content_for'
require 'rack-flash'
require_relative 'lib/core_ext/hash'
require_relative 'helpers/sinatra'
require_relative 'models/track'
require 'taglib'
require 'pathname'
require 'json'

require_relative 'lib/tagger'

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
      tag.delete_if {|key, value| !params[:check].include? key }
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
        body json :album => track.album, :artist => track.artist, :title => track.title, :cover => track.cover
      else
        body json :title => "Track not found."
      end
    else
      body json :album => "Unknown", :artist => "Unknown", :title => "No song", :cover => "blank.png"
    end
  end

  # pjax calls
  aget '/player' do
    if !request.pjax?
      body slim :player
    else
      body pjax_partial :player
    end
  end

  aget '/waveform' do
    if !request.pjax?
      body slim :waveform
    else
      body pjax_partial :waveform
    end
  end

end

