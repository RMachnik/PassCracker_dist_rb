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
  @@URLS = ['http://pl.md5decoder.org/', 'http://md5.gromweb.com/?md5=', 'http://www.md5-hash.com/md5-hashing-decrypt/', 'http://www.google.com/search?q=']

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
    val = crackSingleHash(hash)
    puts "Task is done #{val}!"
    if val.nil? && val.to_s.empty?
      puts "fail with searching it"
    end
    @isWorking = false
    @server.saveDone(hash, val)
  end

  def crackSingleHash(hash)
    @@URLS.each do |url|
      puts "#{url}#{hash}"
      response = Net::HTTP.get URI("#{url}#{hash}")
      wordList = response.split(/\s+/)
      wordList.each do |word|
        nextSplit = word.split(/[:,"<>'()=] */)
        dictionaryAttackResult = dictionaryAttack(hash, nextSplit)
        if !dictionaryAttackResult.nil? && dictionaryAttackResult!=''
          return dictionaryAttackResult
        end
      end
    end
    nil
  end

  def dictionaryAttack(hash, wordList)
    wordList.each do |word|
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
    end.each { |item| dictionaryAttack(hash, item.content.split(/\s+/)) }
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