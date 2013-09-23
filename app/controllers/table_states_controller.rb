class TableStatesController < ApplicationController
  load_resource :suite
  load_resource :table_state, through: :suite, shallow: true
  before_filter :authorize_table_state!

  def show
    render json: @table_state.data
  end

  def select
    current_user.save_setting!(@suite, "datatable_state" => @table_state.data)
    flash[:success] = t(:"table_states.select.success", name: @table_state.name)
    redirect_to color_table_suite_url(@suite)
  end

  def create
    if @table_state.save
      render json: { id: @table_state.id, name: @table_state.name }
    else
      render json: { errors: @table_state.errors.full_messages }, status: 400
    end
  end
  def update
    if @table_state.update_attributes(params[:table_state])
      render json: { id: @table_state.id, name: @table_state.name }
    else
      render json: { errors: @table_state.errors.full_messages }, status: 400
    end
  end

  def destroy
    @table_state.destroy
    render json: {}
  end

  private

  def authorize_table_state!
    if @suite
      authorize! :view, @suite
    elsif @table_state.try(:owner)
      authorize! :view, @table_state.owner
    elsif @table_state
      authorize! params[:action].to_sym, @table_state
    else
      authorize! params[:action].to_sym, TableState
    end
  end
end
