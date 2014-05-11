require 'rinda/ring'
require 'rinda/tuplespace'



DRb.start_service
Rinda::RingServer.new(Rinda::TupleSpace.new)
puts "RingServer started successfully!"
DRb.thread.join