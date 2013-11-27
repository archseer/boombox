require 'bundler/setup'
Bundler.require

Mongoid.load!("mongoid.yml")

require 'fileutils'
require 'sinatra/reloader'
require 'sinatra/json'
require 'sinatra/content_for'
require "better_errors"
require_relative 'helpers/sinatra'
require_relative 'models/user'
require_relative 'models/album'
require_relative 'models/artist'
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

  Rabl.register! # register RABL templates

  Rabl.configure do |config|
    config.include_json_root = false
    config.include_child_root = false
  end

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
    Artist.delete_all
    Album.delete_all
    Tagger.generate_db self
  end

  # Get views rendered for injection
  get '/views/*' do
    filename = params[:splat].first
    slim filename.to_sym, layout: false, :disable_escape => true
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
  before '/api/*' do
    content_type 'application/json'
  end

  get '/api/search/:query' do
    # if string is empty, return all tracks instead of searching for it, speed optimization
    tracks = (params[:query].blank? ? Track : Track.where(:$or => [
      {:title => /#{params[:query]}/i}
    ])).asc(:album, :disc, :track).all

    json tracks
  end

  get '/api/tracks' do
    @tracks = Track.asc(:album, :disc, :track).all
    rabl :'api/tracks'
  end

  get '/api/tracks/:id' do
    if params[:id] != "undefined"
      if @track = Track.find(params[:id])
        rabl :'api/track'
      else
        json :error => "404 - Not Found"
      end
    else
      json :album => "Unknown", :artist => "Unknown", :title => "No song", :cover => "/img/blank.png"
    end
  end

  get '/api/albums' do
    @albums = Album.asc(:name).all
    rabl :'api/albums'
  end

  get '/api/albums/:id' do
    @album = Album.find(params[:id])
    rabl :'api/album'
  end

  get '/api/artists' do
    @artists = Artist.asc(:name).all
    rabl :'api/artists'
  end

  get '/api/artists/:id' do
    @artist = Album.find(params[:id])
    rabl :'api/artist'
  end

  configure :development do
    use BetterErrors::Middleware
    BetterErrors.application_root = File.expand_path("..", __FILE__)
  end

  # start the server if ruby file executed directly
  run! if app_file == $0
end
