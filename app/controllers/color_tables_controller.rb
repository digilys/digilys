class ColorTablesController < ApplicationController
  load_and_authorize_resource :suite
  load_and_authorize_resource through: :suite, shallow: true

  before_filter :instance_filter
  prepend_before_filter :parse_evaluation_ids, only: [ :create, :update ]

  
  def index
    @color_tables = @color_tables.regular
    @color_tables = @color_tables.search(params[:q]).result if has_search_param?
    @color_tables = @color_tables.page(params[:page])
  end

  def show
  end

  def new
  end

  def create
    @color_table.instance = current_instance

    if @color_table.save
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
