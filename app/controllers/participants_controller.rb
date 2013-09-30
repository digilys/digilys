class ParticipantsController < ApplicationController
  load_resource :suite
  load_resource :participant

  before_filter :instance_filter
  before_filter :authorize_suite!

  def new
    @participant.suite = @suite
  end

  def create
    @suite = Suite.find(params[:participant][:suite_id])

    participant_data = process_participant_autocomplete_params(params[:participant])

    group_ids = []

    participant_data.each do |data|
      @suite.participants.create(data) unless @suite.participants.exists?(student_id: data[:student_id])
      group_ids << data[:group_id] if data[:group_id]
    end

    flash[:success] = t(:"participants.create.success")
    redirect_to @suite
  rescue ActiveRecord::RecordInvalid
    @participant.student_id = nil
    @participant.group_id = nil
    render action: "new"
  end

  def confirm_destroy
  end

  def destroy
    suite = @participant.suite
    @participant.destroy

    flash[:success] = t(:"participants.destroy.success")
    redirect_to suite
  end


  private

  def authorize_suite!
    authorize!(:contribute_to, @suite || @participant.suite)
  end

  def instance_filter
    suite = @participant.try(:suite) || @suite
    raise ActiveRecord::RecordNotFound if suite && suite.instance_id != current_instance_id
  end
end
