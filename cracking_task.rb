class CrackingTask
  attr_accessor :hash
  attr_accessor :value
  attr_accessor :done
  attr_accessor :worker

  def initialize(h)
    @hash = h
    @value = nil
    @done = false
    @worker = nil

  end

  def setWorker(w)
    @worker = w
  end

end