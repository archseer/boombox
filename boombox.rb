require 'bundler/setup'
Bundler.require

Mongoid.load!("mongoid.yml")

require 'fileutils'
require 'sinatra/reloader'
require 'sinatra/json'
require 'sinatra/content_for'
require "better_errors"
require_relative 'lib/core_ext/hash'
require_relative 'helpers/sinatra'
require_relative 'models/user'
require_relative 'models/track'
require 'pathname'

require_relative 'lib/tagger'
require_relative 'lib/warden'

class CoffeeHandler < Sinatra::Base
  set :views, File.dirname(__FILE__) + '/coffee'

  get "/coffee/*.js" do
    filename = params[:splat].first
    coffee filename.to_sym
  end
end

class Boombox < Sinatra::Base
  register Sinatra::Reloader
  also_reload "lib/*.rb"
  also_reload "helpers/*.rb"
  also_reload "models/*.rb"

  helpers Sinatra::ContentFor
  helpers Sinatra::JSON
  helpers WebHelpers

  set :server, :thin
  set :port, 8080

  use CoffeeHandler
  use Rack::MethodOverride
  use Rack::Session::Cookie, secret: 'psssshdonttellthistoanyone!'
  use Rack::Flash

  register Sinatra::WardenAuth # our custom Warden module
  get '/' do
    slim :layout, layout: false
  end

  get '/player' do
    slim :player
  end

  get '/waveform' do
    slim :waveform
  end

  get '/cover_view' do
    slim :cover_view
  end

  get '/reset' do
    Track.delete_all
    Tagger.generate_db self
  end

  get '/clear' do
    Track.delete_all
  end

  # Get views rendered for injection
  get '/views/*' do
    filename = params[:splat].first
    slim filename.to_sym, layout: false, :disable_escape => true
  end

  post '/ajax/search' do
    # if string is empty, return all tracks instead of searching for it, speed optimization
    tracks = params[:query].blank? ? Track.asc(:album, :disc, :track).all : Track.where(:$or => [
      {:album => /#{params[:query]}/i},
      {:artist => /#{params[:query]}/i},
      {:title => /#{params[:query]}/i},
      ]).asc(:album, :disc, :track).all
    body partial :tracklist, :locals => {:tracks => tracks}
  end

  post '/ajax/edit-modal' do
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
      tag.delete 'title' # delete per-track specific title
      # delete any keys that aren't checkmarked
      tag.delete_if {|key, value| !params[:check].include? key }
    end

    tracks = Track.find(ids)
    tracks.update_attributes! tag
    tracks.each {|track| track.write_tags }

    body params[:check].inspect
  end

  # API
  get '/api/track/:id' do
    if params[:id] != "undefined"
      track = Track.find params[:id]
      if track
        content_type "application/json"
        track.to_json
      else
        json :error => "404 - Not Found"
      end
    else
      json :album => "Unknown", :artist => "Unknown", :title => "No song", :cover => "blank.png"
    end
  end

  get '/api/tracks/all' do
    json Track.asc(:album, :disc, :track).all
  end

  configure :development do
    use BetterErrors::Middleware
    BetterErrors.application_root = File.expand_path("..", __FILE__)
  end

  # start the server if ruby file executed directly
  run! if app_file == $0
end
