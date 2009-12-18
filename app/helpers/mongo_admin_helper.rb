# Methods added to this helper will be available to all templates in the application.
module MongoAdminHelper
  
  def generate_grid_columns(klass, parent_klass = nil)
    grid_columns = []
    sortable = true
    sortable = false if !klass.include?(MongoMapper::Document)
    grid_columns << { :field => 'id', :label => 'ID', :sortable => sortable }
    keys = klass.keys.select{ |key, value| key != '_id' }
    keys.each do |key, value|
      if parent_klass.nil? || key != parent_klass.to_s.underscore + '_id'
        new_col = { :field => "#{key}", :label => "#{key}", :editable => true, :sortable => sortable }
        if value.type == Boolean
          new_col[:edittype] = "select"
          new_col[:editoptions] = { :value => [["true","yes"], ["false", "no"]] }
        end
        grid_columns << new_col
      end
    end
    grid_columns
  end
  
  def get_many_associations(klass)
    associations = klass.associations.select do |key, value| 
      key if value.type == :many
    end
    associations.map{ |assoc| assoc[0] }
  end
  
  def get_date_fields(klass)
    date_fields = []
    klass.keys.each do |key, value|
      date_fields << "'gs_#{key}'" if value.type == Time
    end
    date_fields.join(',')
  end
  
end
