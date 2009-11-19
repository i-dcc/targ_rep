# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_targ_rep2_session',
  :secret      => '99156a8ebab55c44cdd7758cbef6653df38e8268828cfd0d58e6567e67cb55380efbb6615591f47e204b12f4c8a91eb88329b7b80e3712188055ac5cceb5c45f'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
