class ColorTablesController < ApplicationController
  load_and_authorize_resource :suite
  load_and_authorize_resource through: :suite, shallow: true

  before_filter :instance_filter
  prepend_before_filter :parse_evaluation_ids, only: [ :create, :update ]

  
  def index
    if !current_user.has_role?(:admin)
      @color_tables = @color_tables.with_role([:manager, :editor, :reader], current_user).uniq
    end

    @color_tables = @color_tables.regular
    @color_tables = @color_tables.search(params[:q]).result if has_search_param?
    @color_tables = @color_tables.page(params[:page])
  end

  layout "fullpage", only: :show
  def show
    @user_settings = current_user.settings.for(@color_table).first.try(:data)
  end

  def new
  end

  def create
    @color_table.instance = current_instance

    if @color_table.save
      current_user.add_role(:manager, @color_table)
      flash[:success] = t(:"color_tables.create.success")
      redirect_to @color_table
    else
      render action: "new"
    end
  end

  def edit
  end

  def update
    params[:color_table].delete(:instance)
    params[:color_table].delete(:instance_id)

    if @color_table.update_attributes(params[:color_table])
      flash[:success] = t(:"color_tables.update.success")
      redirect_to @color_table
    else
      render action: "edit"
    end
  end

  def confirm_destroy
  end
  def destroy
    @color_table.destroy
    flash[:success] = t(:"color_tables.destroy.success")
    redirect_to color_tables_url()
  end


  def save_state
    current_user.save_setting!(@color_table, "datatable_state" => JSON.parse(params[:state]))
    render json: { result: "OK" }
  end

  def clear_state
    flash[:notice] = t(:"color_tables.clear_state.success")
    current_user.save_setting!(@color_table, "datatable_state" => nil)
    redirect_to @color_table
  end

  def add_student_data
    @color_table.student_data << params[:key]
    @color_table.save
    redirect_to @color_table
  end


  private

  def instance_filter
    if @color_tables
      @color_tables = @color_tables.where(instance_id: current_instance_id)
    elsif @color_table && suite = @color_table.try(:suite)
      raise ActiveRecord::RecordNotFound if suite.instance_id != current_instance_id
    elsif @color_table && !@color_table.new_record?
      raise ActiveRecord::RecordNotFound if @color_table.instance_id != current_instance_id
    end
  end

  def parse_evaluation_ids
    ids = params[:color_table][:evaluation_ids]
    params[:color_table][:evaluation_ids] = ids.split(",") if ids.is_a?(String)
  end
end
