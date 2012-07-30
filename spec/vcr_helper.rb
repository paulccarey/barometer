require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :fakeweb
  c.configure_rspec_metadata!
  #c.hook_into :webmock # or :fakeweb
end

RSpec.configure do |c|
  # so we can use `:vcr` rather than `:vcr => true`;
  c.treat_symbols_as_metadata_keys_with_true_values = true
end