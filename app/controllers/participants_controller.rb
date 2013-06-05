class ParticipantsController < ApplicationController
  load_and_authorize_resource :suite
  load_and_authorize_resource :participant, through: :suite, shallow: true, except: :create
  before_filter :authorize_suite!

  def new
    @participant.suite = @suite
  end

  def create
    @suite = Suite.find(params[:participant][:suite_id])

    authorize! :update, @suite

    participant_data = process_participant_autocomplete_params(params[:participant])

    group_ids = []

    participant_data.each do |data|
      @suite.participants.create(data) unless @suite.participants.exists?(student_id: data[:student_id])
      group_ids << data[:group_id] if data[:group_id]
    end

    unless group_ids.blank?
      users = Group.find(group_ids).collect(&:users).flatten
      users.each { |u| u.add_role :suite_manager, @suite }
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
    if @participant.try(:suite)
      authorize! :update, @participant.suite
    end
  end
end
