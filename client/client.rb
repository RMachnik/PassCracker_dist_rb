require 'rinda/ring'
require '../cracking_task'
require 'drb'

class Client

  def initialize(filename)
    @crackingTasks = Array.new
    lines = Array.new
    File.new(filename).each_line do |line|
      if m = line.chomp.match(/\b([a-fA-F0-9]{32})\b/)
        lines << m[1]
      end
    end
    lines.uniq!
    lines.each do |x|
      @crackingTasks.push(CrackingTask.new(x))
    end

    puts "Loaded #{@crackingTasks.count} unique hashes"
  end

  def addTasksToServer(server)
    @crackingTasks.each do |task|
      server.registerTask(task)
      puts "Client add task to server #{task.hash}"
    end
  end

  def displayLoadedTasks
    @crackingTasks.each do |task|
      puts task.hash
    end
  end

end

client = Client.new("example.txt")
client.displayLoadedTasks

DRb.start_service
ring_server = Rinda::RingFinger.primary
service = ring_server.read([:cracking_server, nil, nil, nil])
server = service[2]
puts "Server object successfully read: #{server.inspect}"

client.addTasksToServer(server)

DRb.thread.join
