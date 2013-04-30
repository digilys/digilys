class MeetingsController < ApplicationController
  layout "admin"

  def show
    @meeting = Meeting.find(params[:id])
  end

  def new
    @suite         = Suite.find(params[:suite_id])
    @meeting       = Meeting.new
    @meeting.suite = @suite
  end

  # A suite id is required, so we load it separately
  # in order to cause a 404 if it doesn't exist
  def create
    @suite   = Suite.find(params[:meeting][:suite_id])
    @meeting = Meeting.new(params[:meeting])

    if @meeting.save
      flash[:success] = t(:"meetings.create.success")
      redirect_to @meeting
    else
      render action: "new"
    end
  end

  def edit
    @meeting = Meeting.find(params[:id])
  end

  def update
    @meeting = Meeting.find(params[:id])

    if @meeting.update_attributes(params[:meeting])
      flash[:success] = t(:"meetings.update.success")
      redirect_to @meeting
    else
      render action: "edit"
    end
  end

  def confirm_destroy
    @meeting = Meeting.find(params[:id])
  end
  def destroy
    meeting = Meeting.find(params[:id])
    suite = meeting.suite
    meeting.destroy

    flash[:success] = t(:"meetings.destroy.success")
    redirect_to suite
  end
end
