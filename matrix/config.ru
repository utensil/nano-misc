#https://gist.github.com/408193

# Static site using Rack (with expire headers and etag support)... great for hosting static sites on Heroku

require "bundler/setup"
require 'rack/contrib'
require 'rack-rewrite'

use Rack::StaticCache, :urls => ['/styles'], :root => "./"
use Rack::ETag
use Rack::Rewrite do
  rewrite '/', '/matrix.html'
end
run Rack::Directory.new('./')