# encoding: utf-8
require 'logstash/outputs/base'
require 'logstash/namespace'
require 'uri'
require 'rest-firebase'

# Writes event data to the Firebase real-time database https://firebase.google.com/docs/database/rest/retrieve-data[via the REST API]
# This output plugin supports all REST operations provided by Firebase, namely
# - `put`: to create new data or modify existing data under a specific database reference
# - `patch`: to update some of the keys under a specific database reference without replacing all of the data.
# - `post`: to add new data to a list of data
# - `delete`: to remove data under a specific database reference
#
# ==== Example
# 1. send event data to a statically configured path
#
# [source,ruby]
# ----------------------------------
# input {
#   stdin { codec => 'json' }
# }
# output {
#   firebase {
#     url => 'https://test.firebaseio.com'
#     auth => 'secret'
#     path => '/my-path'
#     verb => 'put'
#   }
# }
# ----------------------------------
# 2. send event data to a dynamically configured path
#
# [source,ruby]
# ----------------------------------
# input {
#   stdin { codec => 'json' }
# }
# output {
#   firebase {
#     url => 'https://test.firebaseio.com'
#     auth => 'secret'
#     path => '%{path}'
#     verb => 'put'
#   }
# }
# ----------------------------------
# 3. send event data to a dynamically configured path with a dynamically configured operation
#
# [source,ruby]
# ----------------------------------
# input {
#   stdin { codec => 'json' }
# }
# output {
#   firebase {
#     url => 'https://test.firebaseio.com'
#     auth => 'secret'
#     path => '%{path}'
#     verb => '%{verb}'
#   }
# }
# ----------------------------------
# 4. send a subset of the event data (here all the data contained in the event `data` field) to a
# dynamically configured path with a dynamically configured operation
#
# [source,ruby]
# ----------------------------------
# input {
#   stdin { codec => 'json' }
# }
# output {
#   firebase {
#     url => 'https://test.firebaseio.com'
#     auth => 'secret'
#     path => '%{path}'
#     verb => '%{verb}'
#     target => 'data'
#   }
# }
# ----------------------------------
class LogStash::Outputs::Firebase < LogStash::Outputs::Base
  config_name 'firebase'

  default :codec, 'json'

  # The Firebase URL endpoint
  config :url, :validate => :string, :required => true

  # The secret to use for authenticating
  config :secret, :validate => :string, :required => false

  # The target field whose content will be sent to Firebase. If this setting is omitted, the whole event data will be sent. (default)
  config :target, :validate => :string, :required => false

  # The number of seconds to wait before the connection times out (default: 10s)
  config :firebase_timeout, :validate => :number, :default => 10

  # The number of retries to attempt in case of failures (default: 3)
  config :firebase_retries, :validate => :number, :default => 3

  # The amount of time to wait before refreshing the authentication token, if any (default: 82800s = 23h)
  # Set to -1 to disable the auto-refresh of the authentication token
  config :firebase_auth_ttl, :validate => :number, :default => 82800

  # The operation to carry out. Valid operations are:
  # - `put`: Write or replace data to a defined path (default)
  # - `patch`: Update some of the keys for a defined path without replacing all of the data.
  # - `post`: Add to a list of data
  # - `delete`: Remove data from the specified path
  # - A sprintf style string to change the action based on the content of the event. The value `%{[foo]}`
  #   would use the foo field for the operation
  #
  # For more details on these operations, please check
  # out https://firebase.google.com/docs/database/rest/save-data#section-ways-to-save[Firebase REST docs]
  config :verb, :validate => :string, :default => 'put'

  # The path to write the event data to. It can also be a sprintf style string to use a path present in the content
  # of the event
  config :path, :validate => :string, :required => true

  public
  def register
    @logger.info('Registering firebase output', :url => @url)

    setup_firebase_client!
  end # def register

  private
  def setup_firebase_client!
    @logger.info('Setting up firebase client')

    RestFirebase.pool_size = -1
    @firebase = RestFirebase.new :site => @url,
       :secret => @secret,
       :d => {:auth_data => 'logstash'},
       :log_method => method(:log),
       # `error_callback` would get called each time there's
       # an exception. Useful for monitoring and logging.
       :error_callback => method(:error),
       # `timeout` in seconds
       :timeout => @firebase_timeout,
       # `max_retries` upon failures. Default is: `0`
       :max_retries => @firebase_retries,
       # `retry_exceptions` for which exceptions should retry
       # Default is: `[IOError, SystemCallError]`
       :retry_exceptions => [IOError, SystemCallError, Timeout::Error],
       # `auth_ttl` describes when we should refresh the auth
       # token. Set it to `false` to disable auto-refreshing.
       # The default is 23 hours.
       :auth_ttl => @firebase_auth_ttl > -1 ? @firebase_auth_ttl : false,
       # `auth` is the auth token from Firebase. Leave it alone
       # to auto-generate. Set it to `false` to disable it.
       :auth => false # Ignore auth for this example!

  end # def setup_firebase_client!

  private
  def log(msg)
    @logger.info(msg)
  end

  private
  def error(err)
    @logger.error(err)
  end

  public
  VERBS = %w(put post patch delete)
  def receive(event)
    return if event == LogStash::SHUTDOWN

    # check that path is valid
    path = event.sprintf(@path)
    return @logger.error("Expected valid path, but got '#{path}' instead") unless path =~ URI::REL_URI

    # make sure the verb is in the allowed list
    verb = event.sprintf(@verb)
    return @logger.error("Expected verb to be one of #{VERBS}, got '#{verb}' instead") unless VERBS.include? verb

    @logger.debug('Sinking to Firebase', :url => @url, :verb => verb, :path => path) if @logger.debug?

    # all good, send the data
    data = {}
    unless verb == 'delete'
      data = @target && event.include?(@target) ? event.get(@target) : event.to_hash
    end
    @firebase.method(verb).call(path, data) do |resp|
      if resp.kind_of?(Exception)
        @logger.error('Error while writing to Firebase', :error => resp)
      end
    end

  end # def event

  def close
    @firebase.auth = nil
    RestFirebase.shutdown
  end # def close

end # class LogStash::Outputs::Firebase
