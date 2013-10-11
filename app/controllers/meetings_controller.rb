class MeetingsController < ApplicationController
  load_and_authorize_resource :suite
  load_and_authorize_resource through: :suite, shallow: true

  before_filter :instance_filter

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

  def instance_filter
    suite = @meeting.try(:suite) || @suite
    raise ActiveRecord::RecordNotFound if suite && suite.instance_id != current_instance_id
  end
end
