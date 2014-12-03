require 'sinatra'
require 'rest_client'
# require 'sinatra/reloader' 

set :bind, '0.0.0.0'

get '/' do 
  erb:index
end

get '/movies' do
  erb :'movies/index'
end

get '/actors' do 
  erb :'actors/index'
end


# get '/movies/:id'
#   erb :movies
#   params[:id]
# end