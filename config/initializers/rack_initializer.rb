if Rack::Utils.respond_to?("key_space_limit=")
  Rack::Utils.key_space_limit = 1000000
end