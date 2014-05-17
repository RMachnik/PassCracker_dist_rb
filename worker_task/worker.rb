require '../cracking_task'
require 'digest/md5'
require 'net/http'
require 'rinda/ring'
require 'DRb'
require "google-search"

class Worker
  include DRbUndumped
  attr_accessor :name
  attr_accessor :isWorking

  def initialize(n, s)
    @name=n
    @server=s
    @isWorking=false
  end

  def isActive
    return true
  end

  def assignTask(hash)
    @isWorking = true
    puts "New task assigned to worker: #{name} task: #{hash}!"
    sleep(3)
    val = searchByGoogleSearch(hash)
    puts "Task is done #{val}!"
    if val.nil? && val.to_s.empty?
      puts "fail with searching it"
    end
    @isWorking = false
    @server.saveDone(hash, val)
  end

  def crack_single_hash(hash)
    response = Net::HTTP.get URI("http://www.google.com/search?q=#{hash}")
    wordlist = response.split(/\s+/)
    puts wordlist
    if plaintext = dictionary_attack(hash, wordlist)
      return plaintext
    end
    nil
  end

  def dictionary_attack(hash, wordlist)
    wordlist.each do |word|
      puts word
      if Digest::MD5.hexdigest(word) == hash.downcase
        return word
      end
    end
    nil
  end

  def searchByGoogleSearch(hash)
    Google::Search::Web.new do |search|
      search.query = hash
      search.size = :large
    end.each { |item| dictionary_attack(hash,item.content.split(/\s+/)) }
  end

end


DRb.start_service
ring_server = Rinda::RingFinger.primary
service = ring_server.read([:cracking_server, nil, nil, nil])
server = service[2]
worker = Worker.new("worker12", server);
puts "Server object successfully read: #{server.inspect}"
server.registerWorker(worker)

DRb.thread.join