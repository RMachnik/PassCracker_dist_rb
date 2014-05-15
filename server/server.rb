require 'rinda/ring'
require 'thread'
#require '../worker_task/worker'


require '../cracking_task'

class Server
  include DRbUndumped
  attr_accessor :crackingTasksList
  attr_accessor :availableWorkersList
  attr_accessor :assignedTaskToWorkers
  attr_accessor :results


  def initialize
    @crackingTasksList = Array.new
    @availableWorkersList = Array.new
    @assignedTaskToWorkers = Array.new
    @results = Array.new
    @mutex = Mutex.new
    load_cache
  end

  def registerWorker(worker)
    @mutex.synchronize do
      availableWorkersList << worker
      puts "Worker registered in server: #{worker.name}"
    end
  end

  def registerTask(hash)
    task = CrackingTask.new(hash)
    crackingTasksList.push(task)
    puts "Task added to server: #{task.hash}"
  end

  def saveDone(hash,val)
    task = CrackingTask.new(hash)
    task.value=val
    append_to_cache(task)
    @results.push(task)
  end

  def assignTasks
    begin
      @availableWorkersList.each do |worker|
        @worker = worker
        if !worker.isWorking
          first_not_assigned_task = getFirstNotAssignedTask
          if !first_not_assigned_task.nil?
            worker.assignTask(first_not_assigned_task.hash)
            first_not_assigned_task.setWorker(worker)
            @crackingTasksList.delete(first_not_assigned_task)
            @assignedTaskToWorkers.push(first_not_assigned_task)
          else
            puts "There is no more tasks!"
            checkNotDoneTasks
            sleep(10)
          end
        end
      end
      sleep(2)
    rescue
      deleteInactiveWorker(@worker)
    ensure
      sleep(3)
      assignTasks
    end

  end

  def checkNotDoneTasks
    notDoneTasks = Array.new
    if @assignedTaskToWorkers.size >@results.size
      @crackingTasksList.each do |task|
        if !@results.include?(task)
          task.worker = nil
          task.value = nil
          task.done = false
        end
      end
      if !notDoneTasks.empty?
        assignTasks
      end
    end
    puts "There is any not done tasks!"
  end

  #dlaczego zwraca liste?
  def getFirstNotAssignedTask
    @mutex.synchronize do
      @crackingTasksList.each do |task|
        if task.worker.nil?
          return task
        end
      end
      return nil
    end
  end

  def getTaskAssignedToWorker(worker)
    @mutex.synchronize do
      @assignedTaskToWorkers.each do |task|
        if task.worker.equal?(worker) && task.done=false && task.value = nil
          task.worker = nil
        end
      end
    end
  end


  def load_cache(filename = "cache")
    if File.file? filename
      File.new(filename).each_line do |line|
        if m = line.chomp.match(/^([a-fA-F0-9]{32}):(.*)$/)
          #@cache[m[1]] = m[2]
        end
      end
    end
  end

  def append_to_cache(crackingTask, filename = "cache")
    File.open(filename, "a") do |file|
      file.write "#{crackingTask.hash}:#{crackingTask.value}\n"
    end
  end

  def deleteInactiveWorker(worker)
    puts availableWorkersList.size
    @availableWorkersList.delete(worker)
    puts "Inactive worker was deleted!"
    puts availableWorkersList.size
  end

  def getResults
    return @results
  end

end


#worker = Worker.new("worker");
#server.registerWorker(worker);
#server.deleteInactiveWorker(worker)

DRb.start_service
ring_server = Rinda::RingFinger.primary
puts "Server successfully published touple!"
server = Server.new
ring_server.write([:cracking_server, :Server, server, "Server providing services for cracking stuff..."], Rinda::SimpleRenewer.new)
server.assignTasks
DRb.thread.join
