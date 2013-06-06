require 'sinatra/base'

module Sinatra
  module WardenAuth

    module Helpers
      #def authorized?
      #  session[:authorized]
      #end

      #def authorize!
      #  redirect '/login' unless authorized?
      #end

      #def logout!
      #  session[:authorized] = false
      #end

      def warden
        env['warden']
      end

      def current_user
        warden.user
      end

      def check_authentication
        redirect '/login' unless warden.authenticated?
      end
    end

    def self.registered(app)
      app.helpers WardenAuth::Helpers

      # Warden
      app.use Warden::Manager do |config|
        # Tell Warden how to save our User info into a session.
        # Sessions can only take strings, not Ruby code, we'll store 
        # the User's `id`
        config.serialize_into_session{|user| user.id }
        # Now tell Warden how to take what we've stored in the session
        # and get a User from that information.
        config.serialize_from_session{|id| User.find(id) }

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
        config.failure_app = app
      end

      Warden::Manager.before_failure do |env,opts|
        env['REQUEST_METHOD'] = 'POST'
      end

      Warden::Strategies.add(:password) do
        def valid?
          params['user']['username'] && params['user']['password']
        end

        def authenticate!
          user = User.where(username: params['user']['username']).first

          if !user.nil? && user.authenticate(params['user']['password'])
            success!(user)
          else
            fail!("The username or password you entered is incorrect.")
          end
        end
      end

      app.before do
        pass if ['/login', '/logout', '/auth/unauthenticated'].include? request.path_info
        check_authentication
      end

      app.get '/login' do
        puts "We're on GET /login -- #{flash}"
        slim :login, :layout => 'layouts/login'.to_sym
      end

      app.post '/login' do
        puts "We're on POST /login -- #{flash}"
        warden.authenticate!

        flash[:success] = env['warden'].message
        if session[:return_to] && session[:return_to] != '/login'
          redirect session[:return_to]
        else
          redirect '/'
        end
      end

      app.get '/logout' do
        warden.logout
        redirect '/'
      end

      app.post '/auth/unauthenticated' do
        raise
        session[:return_to] = env['warden.options'][:attempted_path]
        flash[:error] = warden.message || "There was an error while "
         puts "We're on POST /auth/unauthenticated -- #{flash}"
        redirect '/login'
      end

    end
  end

  register WardenAuth
end
