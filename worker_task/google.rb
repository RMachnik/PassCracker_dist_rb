require "google-search"
require 'net/http'
require 'nokogiri'
require 'digest/md5'

[
    "feebffbee6ae120a08e83e979c4487ed"
].each do |hash|
  response = Net::HTTP.get URI("http://pl.md5decoder.org/#{hash}")
  wordList = response.split(/\s+/)
  wordList.each do |word|
    nextSplit = word.split(/[:,"<>'()={}#.] */)
    nextSplit.each do |s|
        if Digest::MD5.hexdigest(s) == hash.downcase
          puts s
        end
    end
  end
  #puts "searching for #{hash}"
  #Google::Search::Web.new do |search|
  #  search.query = hash
  #  #search.size = :large
  #end.each { |item| puts item.uri}
end


