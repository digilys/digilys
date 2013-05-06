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
    student_ids = params[:participant].delete(:student_id).split(/\s*,\s*/)

    student_ids = Hash[student_ids.collect { |i| [i.to_i, nil] }]

    # It's also possible to add participants by sending group
    # ids as a comma separated list
    group_ids = params[:participant].delete(:group_id).split(/\s*,\s*/)

    Group.find(group_ids).each do |group|
      group.student_ids.each do |student_id|
        student_ids[student_id] = group.id
      end
    end

    student_ids.each_pair do |student_id, group_id|
      data = params[:participant].merge(student_id: student_id)

      unless Participant.exists?(data)
        @participant = Participant.new(data)
        @participant.group_id = group_id
        @participant.save!
      end
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
