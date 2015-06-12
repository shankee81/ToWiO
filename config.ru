# This file is used by Rack-based servers to start the application.


# Unicorn self-process killer - https://github.com/kzk/unicorn-worker-killer
# Minimise unicorn memory bloat by restarting workers at regular intervals
require 'unicorn/worker_killer'
use Unicorn::WorkerKiller::MaxRequests, 3072, 4096


require ::File.expand_path('../config/environment',  __FILE__)
run Openfoodnetwork::Application
