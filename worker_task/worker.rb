require '../cracking_task'
require 'digest/md5'
require 'net/http'
require 'rinda/ring'
require 'DRb'

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

  def assignTask(task)
    @isWorking = true
    puts "New task assigned to worker: #{name} task: #{task.hash}!"
    task.worker = self
    sleep(3)
    val = crack_single_hash(task.hash)
    puts "Task is done #{val}!"
    if !val.nil? && !val.to_s.empty?
      task.done = true
    end
    task.value = val
    @isWorking = false
    @server.saveDone(task)
  end

  def crack_single_hash(hash)
    response = Net::HTTP.get URI("http://www.google.com/search?q=#{hash}")
    wordlist = response.split(/\s+/)
    if plaintext = dictionary_attack(hash, wordlist)
      return plaintext
    end
    nil
  end

  def dictionary_attack(hash, wordlist)
    wordlist.each do |word|
      if Digest::MD5.hexdigest(word) == hash.downcase
        return word
      end
    end
    nil
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