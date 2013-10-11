class ActivitiesController < ApplicationController
  load_and_authorize_resource :suite
  load_and_authorize_resource through: :suite, shallow: true

  
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
end
