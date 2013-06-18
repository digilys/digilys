class MeetingsController < ApplicationController
  load_resource :suite
  load_resource :meeting, through: :suite, shallow: true
  before_filter :authorize_meeting!

  def show
  end

  def new
  end

  def create
    if @meeting.save
      flash[:success] = t(:"meetings.create.success")
      redirect_to @meeting
    else
      render action: "new"
    end
  end

  def edit
  end

  def update
    if @meeting.update_attributes(params[:meeting])
      flash[:success] = t(:"meetings.update.success")
      redirect_to @meeting
    else
      render action: "edit"
    end
  end

  def report
    @meeting.activities.build if @meeting.activities.blank?
    @meeting.completed = true
  end

  def submit_report
    if @meeting.update_attributes(params[:meeting])
      flash[:success] = t(:"meetings.submit_report.success")
      redirect_to @meeting
    else
      render action: "report"
    end
  end

  def confirm_destroy
  end
  def destroy
    suite = @meeting.suite
    @meeting.destroy

    flash[:success] = t(:"meetings.destroy.success")
    redirect_to suite
  end


  private

  def authorize_meeting!
    if @suite
      authorize! :contribute_to, @suite
    elsif @meeting.try(:suite)
      authorize! :contribute_to, @meeting.suite
    elsif @meeting
      authorize! params[:action].to_sym, @meeting
    else
      authorize! params[:action].to_sym, Meeting
    end
  end
end
