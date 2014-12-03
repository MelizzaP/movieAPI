require 'sinatra'
require 'rest_client'
# require 'sinatra/reloader' 




set :bind, '0.0.0.0'

get '/' do 
  erb:index
end

get '/movies' do
  @movies = JSON.parse(RestClient.get "http://movies.api.mks.io/movies")
  erb :'movies/index'
end

get '/actors' do 
  @actors = JSON.parse(RestClient.get "http://movies.api.mks.io/actors")
  erb :'actors/index'
end


get '/movies/:id' do
  @actors = JSON.parse(RestClient.get "http://movies.api.mks.io/movies/#{params[:id]}/actors")
  @movie = JSON.parse(RestClient.get "http://movies.api.mks.io/movies/#{params[:id]}")
  erb :'movies/movie_shell'
end

get '/actors/:id' do
  @movies = JSON.parse(RestClient.get "http://movies.api.mks.io/actors/#{params[:id]}/movies")
  @actor = JSON.parse(RestClient.get "http://movies.api.mks.io/actors/#{params[:id]}")
  erb :'actors/actor_shell'
end 


