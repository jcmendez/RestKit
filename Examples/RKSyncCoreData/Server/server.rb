#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra/base'
require 'json'
require 'sinatra/activerecord'

class Human < ActiveRecord::Base
  has_many :cats, :class_name => "Cat", :foreign_key => "owner_id"
end

class Cat < ActiveRecord::Base
  belongs_to :owner, :class_name => "Human", :foreign_key => "owner_id"
end

class RKSyncCoreDataServer < Sinatra::Base
  configure do
    set :logging, true
    set :dump_errors, true
    set :database, 'sqlite://database.db'
    ActiveRecord::Base.include_root_in_json = false
    ActiveSupport::Inflector.inflections do |inflect|
      inflect.irregular 'human', 'humans'
    end
    puts ActiveRecord::Base.pluralize_table_names
    # set :public_folder, Proc.new { root }
    #puts "the humans table doesn't exist" if !database.table_exists?('humans')
  end
  
  before do
    content_type 'application/json'
  end
  
  # GET /humans
  get '/humans' do
    @humans = Human.all
    {"humans" => @humans}.to_json(:include => [:cats])
  end

  # GET /humans/1  
  get '/humans/:id' do
    @human = Human.find(params[:id]) rescue nil
    @human.to_json(:include => [:cats]) if @human
  end
  
  # POST /humans.json 
  # curl -X POST -d "human[name]=Johnny%20Cash" http://127.0.0.1:9292/humans
  post '/humans' do
    begin
      @human = Human.create(params['human'])
      @human.save
      rand(5).times do |x|
        c = @human.cats.create!({:name => "#{@human.name}'s Cat #{x+1}"})
      end
      status 201
    rescue Exception => e
      status 500
    end
    @human.to_json(:include => [:cats])
  end
  
  # DELETE /humans/1.json 
  # curl -X DELETE http://127.0.0.1:9292/humans/1
  delete '/humans/:id' do
    @human = Human.find(params[:id]) rescue nil
    @human.delete if @human
    status 204
  end
  

  run! if app_file == $0
  
end

