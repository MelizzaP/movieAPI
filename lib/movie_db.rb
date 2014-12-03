require 'pg'
require 'rest-client'


class MovieDB
  attr_reader :database, :res, :join_tables_sql
  def initialize
    @database = PG::Connection.open(dbname: 'movie_db')
  end 
  
  
  def create_tables
    movies_sql = %q[
      CREATE TABLE IF NOT EXISTS movies(
        title   varchar,
        id     integer primary key
        );
    ]
    database.exec(movies_sql)
    
    actors_sql = %q[
      CREATE TABLE  IF NOT EXISTS actors(
        name  varchar,
        id    integer primary key
        )
    ]
    database.exec(actors_sql)
    
    movie_actor_sql = %q[
      CREATE TABLE IF NOT EXISTS movie_actor(
        id        serial primary key,
        movie_id  integer references movies (id),
        actor_id integer references actors (id)
        )
    ]
    database.exec(movie_actor_sql)
    
  end
  
  def retrieve_data 
    host = "movies.api.mks.io/"
  	@movies = JSON.parse(RestClient.get host + "movies/")
  # 	@actors = movie_data.map do |movie|pet_shop.rb
  # 	  JSON.parse(RestClient.get host + "movies/" + movie["id"].to_s + "/actors")
  # 	 end
  	 
    @actors = JSON.parse(RestClient.get host + "actors/")
    @movie_actor = @actors.map do |actor|
      JSON.parse(RestClient.get host + "actors/" + actor["id"].to_s + "/movies")
    end
    
    # calling some methods here 
    create_tables
    add_data_to_tables
   	 
  end
  
  
  def add_data_to_tables  
    @movies.each do |movie|
      movie_title = movie["title"]
      movie_id = movie["id"]
      actor_id = 
    
      movie_sql = %q[
        INSERT INTO movies (title, id)
        VALUES ($1,$2)
        ]
        database.exec(movie_sql, [movie_title,movie_id])
    end
    
    @actors.each do |actor|
      actor_name = actor['name']
      actor_id = actor['id']
  
      actor_sql = %q[
        INSERT INTO actors (name,id)
        VALUES ($1,$2)
      ] 
      database.exec(actor_sql, [actor_name, actor_id])
    end
    
    @movie_actor.flatten.each do |movie|
      actor_movie_id = movie['id']
      actor_id = movie['actorId']
      movie_actor_sql = %q[
        INSERT INTO movie_actor (actor_id,movie_id)
        VALUES ($1,$2)
      ]
      database.exec(movie_actor_sql, [actor_id, actor_movie_id])
    end
    
  end
  
  def sort_actors_alphabetically
    sql = %q[
      SELECT name
      FROM actors
      ORDER BY name;
    ]
    result = database.exec(sql)
    result.entries.each {|actor| puts actor['name']}
#     #I decided to sort these using the select function
#       because I did not want to put any unneeded loops
#       into my my method
  end

  def sort_movies_alphabetically
    sql = %q[
      SELECT title
      FROM movies
      ORDER BY title;
    ]  
    result = database.exec(sql)
    result.entries.each {|movie| puts movie['title']}
    
  end

  def actors_by_appearances
    sql = %q[
      SELECT 
        name,
        count(name)
      FROM movie_actor
      INNER JOIN actors
      ON movie_actor.actor_id = actors.id
      GROUP BY name
      ORDER BY count DESC
      LIMIT(5)
    ]
    result = database.exec(sql)
    puts "Actor | Appearances"
    puts "-------------------------"
    result.entries.each {|actor| puts "#{actor['name']} | #{actor['count']}"}
    
  end

 def join_tables(more_sql="")
    @join_tables_sql = %q[
      SELECT
        movies.title,
        actors.name
      FROM movie_actor
      INNER JOIN actors
      ON movie_actor.actor_id = actors.id
      INNER JOIN movies
      ON movie_actor.movie_id = movies.id
    ]
    @res = database.exec(join_tables_sql + more_sql)
  end


  def group_actors_by_movie
    more_sql = %q[
      GROUP BY
        title,
        name
      ORDER BY title;
    ]
    join_tables(more_sql)
    title = ""
    res.entries.each do |entry|
      if title == entry['title']
        puts "   - #{entry['name']}"
      else
        title = entry['title']
        puts entry['title']
        puts "   - #{entry['name']}"
      end
    end
  end

   
  def actors_for_a_specific_movie(title)
    sql = %q[
      WHERE title = ($1)
      OR title LIKE ($2)
      ]
      result = database.exec(join_tables_sql + sql, [title, "#{title}%"])
      if result.entries[0]['title'] == title
        puts "Actors from #{title}:"
        result.entries.each {|entry| puts entry["name"]}
      else
        puts "The closest movies to your input are:"
        similar_titles = result.entries.uniq {|entry| entry['title']}
        similar_titles.each {|entry| puts entry['title']}
      end
  end
  
  def movies_for_a_specific_actor(name)
    sql = %q[
      WHERE name = ($1)
      OR name LIKE ($2)
      ]
    result = database.exec(join_tables_sql + sql, [name, "#{name}%"])
    if result.entries[0]['name'] == name
      puts "Movies featuring #{name}:"
      result.entries.each {|entry| puts entry["title"]}
    else
      puts "The closest actors to your input are:"
      similar_names = result.entries.uniq {|entry| entry['name']}
      similar_names.each {|entry| puts entry['name']}
    end 
  
  end
  
  def actor_to_coactor(name)
    titles = []
    coactors = []
    join_tables
    res.entries.each do |entry|
      if entry['name'].match name
       titles << entry['title']
      end
    end
    res.entries.each do |entry|
      if titles.include? entry['title']
        coactors << entry['name']
      end
    end
    coactors.delete(name)
    puts "Coactors of #{name}:"
    puts coactors.uniq
  end
  
  def two_actors_movies(name1,name2)
   sql = %q[
     WHERE 
      name = ($1)
     OR
      name = ($2)
   ]
   titles = []
   #this grabs all the titles with either actor
   result = database.exec(join_tables_sql + sql, [name1,name2])
   result.entries.each { |entry| titles << entry['title']}
   #this prints out any title that appears more that once
   #meaning the title features both actors
   puts "Movies that have both #{name1} and #{name2}:"
   puts titles.select { |t| titles.count(t) > 1 }.uniq 
  end

  def terminal_client
    puts "******************************************"
    puts "        WELCOME TO THE MOVIE DB"
    puts "------------------------------------------"
    puts "Please Select one of the following options"
    puts "1 => Retrieve a list of all movies"
    puts "2 => Retrieve a list of all actors"
    puts "3 => Find all the actors by movie title"
    puts "4 => Find all movie titles by featuring an actor"
    puts "5 => Find all the coactors of an actor"
    puts "6 => Exit"
    terminal = 'open'
    
    while terminal == 'open' do
      input = gets.chomp.to_i
      if input == 1
        sort_movies_alphabetically()
      elsif input == 2
        sort_actors_alphabetically()
      elsif input == 3
        puts "What movie would you like to select?"
        movie = gets.chomp
        actors_for_a_specific_movie(movie)
      elsif input == 4
        puts "What actor would you like to select?"
        actor = gets.chomp
        movies_for_a_specific_actor(actor)
      elsif input == 5
        puts "What actor would you like to select?"
        actor = gets.chomp
        actor_to_coactor(actor)
      elsif input == 6
        terminal = 'close'
      else
        puts "Sorry, that is not a valid option"
      end
    end  
  end
  
end


 
    