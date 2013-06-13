class ActivitiesController < ApplicationController
  load_resource :suite
  load_resource :activity, through: :suite, shallow: true
  before_filter :authorize_activity!

  
  def show
  end

  def edit
  end

  def update
    if @activity.update_attributes(params[:activity])
      flash[:success] = t(:"activities.update.success.#{@activity.type}")
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
      flash[:success] = t(:"activities.submit_report.success.#{@activity.type}")
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

    flash[:success] = t(:"activities.destroy.success.#{@activity.type}")
    redirect_to suite
  end

  private

  def authorize_activity!
    if @suite
      authorize! :contribute_to, @suite
    elsif @activity.try(:suite)
      authorize! :contribute_to, @activity.suite
    elsif @activity
      authorize! params[:method].to_sym, @activity
    else
      authorize! params[:method].to_sym, Activity
    end
  end
end
