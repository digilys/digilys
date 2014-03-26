RSpec::Matchers.define :touch do |model|
  match do |given_proc|
    updated_at = model.updated_at

    Timecop.freeze(Time.now + 5.minutes) do
      given_proc.call
    end

    model.reload.updated_at > updated_at
  end
end
