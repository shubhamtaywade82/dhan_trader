Delayed::Worker.destroy_failed_jobs = false
Delayed::Worker.max_attempts        = 3
Delayed::Worker.sleep_delay         = 10   # seconds between polls
Delayed::Worker.default_queue_name  = 'default' 