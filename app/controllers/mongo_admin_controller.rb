class MongoAdminController < ApplicationController
  
  def index
    build_klasses
  end
  
  def show
    @klass = get_klass_from_param(params[:id])
    conditions = generate_conditions
    records = @klass.paginate(:page => params[:page], :per_page => params[:rows], 
                              :conditions => conditions, :order => generate_order)
    
    respond_to do |format|
      format.html
      format.json do
        columns = @klass.column_names.select{ |col| col != '_id' }
        render :json => records.to_jqgrid_json([:_id] + columns.map{ |name| name.to_sym }, 
                                               params[:page], params[:rows], @klass.count(conditions))
      end
    end
  end
  
  def associations
    @klass = get_klass_from_param(params[:id])
    if params[:parent]
      parent_klass = get_klass_from_param(params[:parent])
      parent_model = parent_klass.find(params[:parent_id])      
      if @klass.include?(MongoMapper::Document)
        children = parent_model.send(params[:id].downcase.pluralize)
        records = children.paginate(:page => params[:page], :per_page => params[:rows], 
                                    :conditions => generate_conditions, :order => generate_order)
        total_size = children.size
      else
        records = parent_model.send(params[:id].underscore.pluralize)
        total_size = records.size
      end
    else
      records = []
      total_size = records.size
    end
    
    respond_to do |format|
      format.json { render :json => records.to_jqgrid_json(generate_assoc_json(records, @klass, parent_klass), 
                                                           params[:page], params[:rows], total_size) }
    end
  end
  
  def post_data
    @klass = get_klass_from_param(params[:klass])
    model_params = generate_model_params(@klass)
    
    if params[:oper] == 'add'
      @klass.create(model_params)
    elsif params[:oper] == 'del'
      model = @klass.find(params[:id])
      model.destroy
    else
      model = @klass.find(params[:id])
      model.update_attributes(model_params)
    end
    
    render :nothing => true
  end
  
  def post_assoc_data
    @klass = get_klass_from_param(params[:klass])
    model_params = generate_model_params(@klass)
    
    parent_klass = get_klass_from_param(params[:parent])
    parent_model = parent_klass.find(params[:parent_id])
    children = parent_model.send(params[:klass].underscore.pluralize)
    
    if params[:oper] == 'add'
      children << @klass.new(model_params)
    elsif params[:oper] == 'del'
      if @klass.include?(MongoMapper::Document)
        @klass.find(params[:id]).destroy
      else
        children.delete_if{|child| child.id.to_s == params[:id] }
      end
    else
      children.each do |child|
        if child.id.to_s == params[:id]
          child.update_attributes(model_params)
          break
        end
      end
    end
    
    parent_model.save
    
    render :nothing => true
  end
  
  private
  
  def generate_assoc_json(records, klass, parent_klass)
    foreign_key = parent_klass.to_s.underscore + '_id'
    columns = klass.column_names.select{ |col| col != '_id' && col != foreign_key }
    [:_id] + columns.map{ |name| name.to_sym }
  end
  
  def generate_conditions
    conditions = {}
    if params[:_search] == 'true'
      @klass.keys.each do |key, value|
        if params[key.to_sym].present?
          if value.type == String
            conditions[key.to_sym] = /#{params[key.to_sym]}/
          elsif value.type == Time
            selected_date = Date.parse(params[key.to_sym])
            conditions[key.to_sym] = { '$gt' => selected_date.to_time, '$lt' => (selected_date + 1.day).to_time }
          elsif value.type == Integer
            conditions[key.to_sym] = params[key.to_sym].to_i
          elsif value.type == Float
            conditions[key.to_sym] = params[key.to_sym].to_f
          elsif value.type == Boolean
            bool = [true, 'true', 1, '1', 'T', 't'].include?(params[key.to_sym].downcase)
            conditions[key.to_sym] = bool
          end
        end
      end
    end
    conditions
  end
  
  def generate_order
    sidx = '_id' if params[:sidx].nil?
    sord = 'asc' if params[:sord].nil?
    "#{params[:sidx]} #{params[:sord]}"
  end
  
  def generate_model_params(klass)
    model_params = {}
    columns = klass.column_names.select { |col| col != '_id' }
    columns.each do |col|
      if params[:parent]
        model_params[col.to_sym] = params[col.to_sym] if col != params[:parent].downcase + '_id'
      else
        model_params[col.to_sym] = params[col.to_sym]
      end
    end
    model_params
  end
  
  def get_klass_from_param(klass_name)
    begin
      klass = klass_name.camelize.constantize
    rescue TypeError => e # in case no params[:klass] is supplied
      flash[:error] = 'no params[:klass] was supplied'
      redirect_to :action => 'index'
    rescue NameError # in case wrong params[:klass] is supplied
      flash[:error] =  'wrong params[:klass] was supplied'
      redirect_to :action => 'index'
    end
  end

  def build_klasses
    unless defined? $mongo_admin_klasses
      model_dir = File.join(RAILS_ROOT,'app','models')
      model_names = Dir.chdir(model_dir) { Dir["**/*.rb"] }
      klasses = get_klasses(model_names)
      $mongo_admin_klasses = keep_only_mongo_klasses(klasses).sort_by {|r| r.name.underscore}
    end
    @klasses = $mongo_admin_klasses
  end

  def get_klasses(model_names)
    model_names.map do |model_name|
      klass_name = model_name.sub(/\.rb$/,'').camelize
      Kernel.const_get(klass_name)
    end
  end
  
  def keep_only_mongo_klasses(klasses)
    klasses.select { |k| k.include?(MongoMapper::Document) }
  end

end