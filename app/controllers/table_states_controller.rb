class TableStatesController < ApplicationController
  load_and_authorize_resource :color_table
  load_and_authorize_resource through: :color_table, shallow: true

  before_filter :instance_filter

  def show
    render json: @table_state.data
  end

  def select
    current_user.save_setting!(@base, "datatable_state" => @table_state.data)
    flash[:success] = t(:"table_states.select.success", name: @table_state.name)
    redirect_to @base
  end

  def create
    duplicate = TableState.where(
      base_id: @table_state.base_id,
      base_type: @table_state.base_type
    ).where([
      'name ilike ?', @table_state.name
    ]).first

    if duplicate
      @table_state = duplicate
      @table_state.data = params[:table_state][:data]
    end

    if @table_state.save
      render json: {
        id:   @table_state.id,
        name: @table_state.name,
        urls: {
          default: table_state_path(@table_state),
          select:  select_table_state_path(@table_state)
        }
      }
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
    render json: { id: @table_state.id }
  end

  private

  def instance_filter
    @base = @table_state.try(:base) || @color_table

    if @base && @base.respond_to?(:instance_id)
      if @base.instance_id.nil? && @base.respond_to?(:suite)
        if @base.suite.instance_id != current_instance_id
          raise ActiveRecord::RecordNotFound
        end
      elsif @base.instance_id != current_instance_id
        raise ActiveRecord::RecordNotFound
      end
    end
  end
end
