# Model for storing jobs/tasks persisted to the database

class BdrbJobQueue < ActiveRecord::Base
  validates_uniqueness_of :job_key, scope: [:worker_name, :worker_key]
  
  # find next task from the table
  def self.find_next(worker_name,worker_key = nil)
    returned_job = nil
    ActiveRecord::Base.verify_active_connections! if ActiveRecord::Base.respond_to?(:verify_active_connections!)
    transaction do
      #use ruby time stamps for time calculations as db might have different times than what is calculated by ruby/rails
      query = where(worker_name: worker_name, taken: 0).where("scheduled_at <= ?", Time.now.utc).lock(true).order('priority desc')
      query = query.where(worker_key: worker_key) if worker_key
      if t_job = query.first
        t_job.taken = 1
        t_job.started_at = Time.now.utc
        t_job.save
        returned_job = t_job
      end
    end
    returned_job
  end

  #these accessors get around any possible character encoding issues with the database
  def args=(args)
    write_attribute(:args, Base64.encode64(args))
  end

  def args
    Base64.decode64(read_attribute(:args))
  end

  # release a job and mark it to be unfinished and free.
  # useful, if inside a worker, processing of this job failed and you want it to process later
  def release_job
    ActiveRecord::Base.verify_active_connections! if ActiveRecord::Base.respond_to?(:verify_active_connections!)
    self.class.transaction do
      self.taken = 0
      self.started_at = nil
      self.save
    end
  end

  # insert a new job for processing. jobs added will be automatically picked by the appropriate worker
  def self.insert_job(options = { })
    ActiveRecord::Base.verify_active_connections! if ActiveRecord::Base.respond_to?(:verify_active_connections!)
    transaction do
      options.merge!(submitted_at: Time.now.utc, finished: 0, taken: 0)
      t_job = new(options)
      t_job.save
    end
  end

  # remove a job from table
  def self.remove_job(options = { })
    ActiveRecord::Base.verify_active_connections! if ActiveRecord::Base.respond_to?(:verify_active_connections!)
    transaction do
      t_job_id = where(options.merge(finished: 0, taken: 0)).lock(true).first
      delete(t_job_id)
    end
  end

  # Mark a job as finished
  def finish!
    ActiveRecord::Base.verify_active_connections! if ActiveRecord::Base.respond_to?(:verify_active_connections!)
    self.class.transaction do
      self.finished = 1
      self.finished_at = Time.now.utc
      self.job_key = "finished_#{Time.now.utc.to_i}_#{job_key}"
      self.save
    end
    Thread.current[:persistent_job_id] = nil
    Thread.current[:job_key] = nil
    nil
  end
end
