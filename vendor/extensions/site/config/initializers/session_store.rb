# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_ct_session',
  :secret      => '58d90c775a1ac9a42a1f6c65c14efb0d86739a6d845def47ca81fd0944125ec377edbf3eb1db0c8cdb0e7a463f54f2317525e58d940f02b8f6234165afb8af55'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store