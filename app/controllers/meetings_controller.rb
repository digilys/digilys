class MeetingsController < ApplicationController
  layout "admin"

  # Needs to execute before load_and_authorize_resource
  before_filter :remove_empty_activities, only: :submit_report

  load_and_authorize_resource :suite
  load_and_authorize_resource :meeting, through: :suite, shallow: true
  before_filter :authorize_suite!

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
    @meeting.activities.build
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

  def authorize_suite!
    if @meeting.try(:suite)
      authorize! :update, @meeting.suite
    end
  end

  def remove_empty_activities
    params[:meeting][:activities_attributes].reject! { |key, value|
      value.try(:[], :name).blank? &&
        value.try(:[], :description).blank?
    }
  end
end
