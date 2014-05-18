require 'rinda/ring'
require 'drb'

class Client

  def initialize(filename)
    @hashes = Array.new
    File.new(filename).each_line do |line|
      if m = line.chomp.match(/\b([a-fA-F0-9]{32})\b/)
        @hashes << m[1]
      end
    end
    @hashes.uniq!
  end

  def addTasksToServer(server)
    @hashes.each do |hash|
      server.registerTask(hash)
      puts "Client add task to server #{hash}"
    end
  end

  def displayLoadedTasks
    @hashes.each do |hash|
      puts hash
    end
  end

end

client = Client.new("example.txt")
#client.displayLoadedTasks

DRb.start_service
ring_server = Rinda::RingFinger.primary
service = ring_server.read([:cracking_server, nil, nil, nil])
server = service[2]
puts "Server object successfully read: #{server.inspect}"

client.addTasksToServer(server)

DRb.thread.join
