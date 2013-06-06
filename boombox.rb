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
require_relative 'models/track'
require 'pathname'
require 'json'

require_relative 'lib/tagger'

# disable running by default, otherwise just requiring it would trigger a duplicate
set :run, false

class CoffeeHandler < Sinatra::Base
  set :views, File.dirname(__FILE__) + '/coffee'

  get "/coffee/*.js" do
    filename = params[:splat].first
    coffee filename.to_sym
  end
end

class Sinatra::Request
  def pjax?
    env['HTTP_X_PJAX'] || self['_pjax']
  end
end

class Boombox < Sinatra::Base
  register Sinatra::Reloader
  register Sinatra::Async
  also_reload "helpers/*.rb"
  also_reload "models/*.rb"

  helpers Sinatra::ContentFor
  helpers Sinatra::JSON
  helpers WebHelpers

  set :server, :thin
  set :port, 8080

  configure :development do
    use BetterErrors::Middleware
    BetterErrors.application_root = File.expand_path("..", __FILE__)
  end

  use CoffeeHandler
  use Rack::MethodOverride

  use Rack::Session::Cookie#, secret: ''

  # Warden
  use Warden::Manager do |config|
    # Tell Warden how to save our User info into a session.
    # Sessions can only take strings, not Ruby code, we'll store 
    # the User's `id`
    config.serialize_into_session{|user| user.id }
    # Now tell Warden how to take what we've stored in the session
    # and get a User from that information.
    config.serialize_from_session{|id| User.get(id) }

    config.scope_defaults :default,
      # "strategies" is an array of named methods with which to
      # attempt authentication. We have to define this later.
      strategies: [:password],
      # The action is a route to send the user to when
      # warden.authenticate! returns a false answer. We'll show
      # this route below.
      action: 'auth/unauthenticated'
    # When a user tries to log in and cannot, this specifies the
    # app to send the user to.
    config.failure_app = self
  end

  Warden::Manager.before_failure do |env,opts|
    env['REQUEST_METHOD'] = 'POST'
  end

  Warden::Strategies.add(:password) do
    def valid?
      params['user']['username'] && params['user']['password']
    end

    def authenticate!
      user = User.first(username: params['user']['username'])

      if user.nil?
        fail!("The username you entered does not exist.")
        flash.error = ""
      elsif user.authenticate(params['user']['password'])
        flash.success = "Successfully Logged In"
        success!(user)
      else
        fail!("Could not log in")
      end
    end
  end

  def warden_handler
      env['warden']
  end

  def current_user
      warden_handler.user
  end

  def check_authentication
      redirect '/login' unless warden_handler.authenticated?
  end

  # end Warden

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

  before do
    pass if request.path_info == '/login'
    check_authentication
  end

  get '/' do
    slim :index
  end

  get '/login' do
    slim :login, :layout => 'layouts/login'.to_sym
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

  post '/ajax/search' do
    # if string is empty, return all tracks instead of searching for it, speed optimization
    tracks = params[:query].blank? ? Track.desc(:album, :disc, :track).all : Track.where(:$or => [
      {:album => /#{params[:query]}/i},
      {:artist => /#{params[:query]}/i},
      {:title => /#{params[:query]}/i},
      ]).desc(:album, :disc, :track).all
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

  
  before do
    if request.pjax? # Disable layout if request is via pjax
      @default_layout = false
    else
      @default_layout = 'layouts/application'.to_sym
    end
  end

  # start the server if ruby file executed directly
  run! if app_file == $0
end
