class ParticipantsController < ApplicationController
  layout "admin"

  def new
    @suite             = Suite.find(params[:suite_id])
    @participant       = Participant.new
    @participant.suite = @suite
  end

  # A suite id is required, so we load it separately
  # in order to cause a 404 if it doesn't exist
  def create
    @suite = Suite.find(params[:participant][:suite_id])

    participant_data = process_participant_autocomplete_params(params[:participant])

    participant_data.each do |data|
      @suite.participants.create(data) unless @suite.participants.exists?(student_id: data[:student_id])
    end

    flash[:success] = t(:"participants.create.success")
    redirect_to @suite
  rescue ActiveRecord::RecordInvalid
    @participant.student_id = nil
    @participant.group_id = nil
    render action: "new"
  end

  def confirm_destroy
    @participant = Participant.find(params[:id])
  end

  def destroy
    participant = Participant.find(params[:id])
    suite = participant.suite
    participant.destroy

    flash[:success] = t(:"participants.destroy.success")
    redirect_to suite
  end
end
