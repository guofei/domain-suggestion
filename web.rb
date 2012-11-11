# -*- coding: utf-8 -*-
require 'sinatra'
require 'mongoid'
require 'redis'
require 'eventmachine'
require 'haml'
require 'erb'
require 'json'
require 'whois'
require 'net/http'

configure do
  Mongoid.load!("mongoid.yml")
  EXPIRE_TIME = 3600
  HOSTS = ["http://intense-fortress-7892.herokuapp.com", "http://domiancheck-kaku.rhcloud.com"]

  url = "redis://rookitcn:c3563723198b36df65b6193e9259cfd5@slimehead.redistogo.com:9319/"
  uri = URI.parse(url)
  REDIS = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password, :thread_safe => true)
end

class Keywords
  include Mongoid::Document
  field :key, :type => String
end

class JKeywords
  include Mongoid::Document
  field :key, :type => String
end

def get_result(params)
  cache_control(:no_cache)
  content_type :json, 'charset' => 'utf-8'
  domain = params[:domain]
  tdl = params[:tdl]
  dic = params[:dic]
  if params[:dic] == 'Japanese Dictionary' then words_class = Class.const_get("JKeywords") else words_class = Class.const_get("Keywords") end
  place = params[:place].to_i

  obj = Hash.new
  count = 0
  words_class.each do |word|
    if place == 1 then url = "#{word.key}#{domain}.#{tdl}" else url = "#{domain}#{word.key}.#{tdl}" end
    res = REDIS.get(url)
    obj.store(url, res)
    if res != nil
      count += 1
    end
  end

  obj.store("percent?", count*100/words_class.count)
  finish = REDIS.get(domain)
  obj.store("isfinished?", finish)
  obj.to_json
end

# test--------------
get '/test' do
  REDIS.client.to_json
end

# front-end---------
get '/' do
  erb :index
end

get '/get/:domain/:tdl' do
  cache_control(:no_cache)
  content_type :json, 'charset' => 'utf-8'
  domain = params[:domain]
  tdl = params[:tdl]
  dic = params[:dic]
  dic = 'English Dictionary' if dic != 'Japanese Dictionary'
  if params[:dic] == 'Japanese Dictionary' then words_class = Class.const_get("JKeywords") else words_class = Class.const_get("Keywords") end
  if params[:place].to_i == 1 then place = 1 else place = 0 end

  ret = true
  EM::defer do
    HOSTS.each do |host|
      begin
        url = URI.parse(URI.escape "#{host}/api/getallasync/#{domain}/#{tdl}?place=#{place}&dic=#{dic}")
        Net::HTTP.get_print url
      rescue => e
        ret = host
      end
    end
  end
  ret.to_json
end

get '/result/:domain/:tdl' do
  get_result(params)
end

# back-end----------

get '/api/getallasync/:domain/:tdl' do
  cache_control(:no_cache)
  content_type :json, 'charset' => 'utf-8'
  domain = params[:domain]
  tdl = params[:tdl]
  dic = params[:dic]
  if params[:dic] == 'Japanese Dictionary' then words_class = Class.const_get("JKeywords") else words_class = Class.const_get("Keywords") end
  place = params[:place].to_i

  REDIS.set(domain, 0)
  REDIS.expire(domain, EXPIRE_TIME)
  EM::defer do
    words_class.each do |word|
      if place == 1 then url = "#{word.key}#{domain}.#{tdl}" else url = "#{domain}#{word.key}.#{tdl}" end
      if REDIS.get(url) == nil
        begin
          REDIS.set(url, -2)
          ans = Whois.whois(url)
          if ans.registered? then REDIS.set(url, 1) else REDIS.set(url, 0) end
        rescue => e
          REDIS.set(url, -2)
        end
        REDIS.expire(url, EXPIRE_TIME)
      end
    end
    REDIS.set(domain, 1)
    REDIS.expire(domain, EXPIRE_TIME)
  end
  200.to_json
end

get '/api/result/:domain/:tdl' do
  get_result(params)
end

get '/abc/keywords' do

end

get '/abc/keywords/new' do
end

get '/cache/reset' do
  REDIS.flushdb
end
