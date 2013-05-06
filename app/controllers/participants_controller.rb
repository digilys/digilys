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

    # It's possible to create multiple participants by sending
    # student_id as a comma separated list of ids
    params[:participant].delete(:student_id).split(/\s*,\s*/).each do |student_id|
      data = params[:participant].merge(student_id: student_id)

      unless Participant.exists?(data)
        @participant = Participant.new(data)
        @participant.save!
      end
    end

    flash[:success] = t(:"participants.create.success")
    redirect_to @suite
  rescue ActiveRecord::RecordInvalid
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
