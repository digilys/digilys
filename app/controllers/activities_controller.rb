class ActivitiesController < ApplicationController
  load_and_authorize_resource :suite
  load_and_authorize_resource :activity, through: :suite, shallow: true
  before_filter :authorize_suite!

  
  def show
  end

  def edit
  end

  def update
    if @activity.update_attributes(params[:activity])
      flash[:success] = t(:"activities.update.success")
      redirect_to @activity
    else
      render action: "edit"
    end
  end

  def report
    @activity.status = :closed
  end

  def submit_report
    if @activity.update_attributes(params[:activity])
      flash[:success] = t(:"activities.submit_report.success")
      redirect_to @activity
    else
      render action: "report"
    end
  end

  def confirm_destroy
  end
  def destroy
    suite = @activity.suite
    @activity.destroy

    flash[:success] = t(:"activities.destroy.success")
    redirect_to suite
  end

  private

  def authorize_suite!
    if @activity.try(:suite)
      authorize! :update, @activity.suite
    end
  end
end
