class ApplicationService
  class Failure < StandardError; end

  Result = Data.define(:value, :error) do
    def success?
      error.nil?
    end

    def failure?
      !success?
    end
  end

  def self.call(...)
    new(...).call
  end

  def call
    Result.new(value: perform, error: nil)
  rescue Failure => e
    Result.new(value: nil, error: e.message)
  end

  private
    def fail!(message)
      raise Failure, message
    end
end
