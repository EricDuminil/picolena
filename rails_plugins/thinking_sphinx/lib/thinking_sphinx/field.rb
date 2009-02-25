module ThinkingSphinx
  # Fields - holding the string data which Sphinx indexes for your searches.
  # This class isn't really useful to you unless you're hacking around with the
  # internals of Thinking Sphinx - but hey, don't let that stop you.
  #
  # One key thing to remember - if you're using the field manually to
  # generate SQL statements, you'll need to set the base model, and all the
  # associations. Which can get messy. Use Index.link!, it really helps.
  # 
  class Field
    attr_accessor :alias, :columns, :sortable, :associations, :model
    
    # To create a new field, you'll need to pass in either a single Column
    # or an array of them, and some (optional) options. The columns are
    # references to the data that will make up the field.
    #
    # Valid options are:
    # - :as       => :alias_name 
    # - :sortable => true
    #
    # Alias is only required in three circumstances: when there's
    # another attribute or field with the same name, when the column name is
    # 'id', or when there's more than one column.
    # 
    # Sortable defaults to false - but is quite useful when set to true, as
    # it creates an attribute with the same string value (which Sphinx converts
    # to an integer value), which can be sorted by. Thinking Sphinx is smart
    # enough to realise that when you specify fields in sort statements, you
    # mean their respective attributes.
    #
    # Here's some examples:
    #
    #   Field.new(
    #     Column.new(:name)
    #   )
    #
    #   Field.new(
    #     [Column.new(:first_name), Column.new(:last_name)],
    #     :as => :name, :sortable => true
    #   )
    # 
    #   Field.new(
    #     [Column.new(:posts, :subject), Column.new(:posts, :content)],
    #     :as => :posts
    #   )
    # 
    def initialize(columns, options = {})
      @columns      = Array(columns)
      @associations = {}
      
      @alias        = options[:as]
      @sortable     = options[:sortable] || false
    end
    
    # Get the part of the SELECT clause related to this field. Don't forget
    # to set your model and associations first though.
    #
    # This will concatenate strings if there's more than one data source or
    # multiple data values (has_many or has_and_belongs_to_many associations).
    # 
    def to_select_sql
      clause = @columns.collect { |column|
        column_with_prefix(column)
      }.join(', ')
      
      clause = "CONCAT_WS(' ', #{clause})" if concat_ws?
      clause = "GROUP_CONCAT(#{clause} SEPARATOR ' ')" if is_many?
      
      "CAST(#{clause} AS CHAR) AS #{@model.connection.quote_column_name(unique_name)}"
    end
    
    # Get the part of the GROUP BY clause related to this field - if one is
    # needed. If not, all you'll get back is nil. The latter will happen if
    # there's multiple data values (read: a has_many or has_and_belongs_to_many
    # association).
    #
    def to_group_sql
      case
      when is_many?, ThinkingSphinx.use_group_by_shortcut?
        nil
      else
        @columns.collect { |column|
          column_with_prefix(column)
        }
      end
    end
    
    # Returns the unique name of the field - which is either the alias of
    # the field, or the name of the only column - if there is only one. If
    # there isn't, there should be an alias. Else things probably won't work.
    # Consider yourself warned.
    #
    def unique_name
      if @columns.length == 1
        @alias || @columns.first.__name
      else
        @alias
      end
    end
    
    private
    
    # Indication of whether the columns should be concatenated with a space
    # between each value. True if there's either multiple sources or multiple
    # associations.
    # 
    def concat_ws?
      @columns.length > 1 || multiple_associations?
    end
    
    # Checks the association tree for each column - if they're all the same,
    # returns false.
    # 
    def multiple_sources?
      first = associations[@columns.first]
      
      !@columns.all? { |col| associations[col] == first }
    end
    
    # Checks whether any column requires multiple associations (which only
    # happens for polymorphic situations).
    # 
    def multiple_associations?
      associations.any? { |col,assocs| assocs.length > 1 }
    end
    
    # Builds a column reference tied to the appropriate associations. This
    # dives into the associations hash and their corresponding joins to
    # figure out how to correctly reference a column in SQL.
    #
    def column_with_prefix(column)
      if associations[column].empty?
        "#{@model.quoted_table_name}.#{@model.connection.quote_column_name(column.__name)}"
      else
        associations[column].collect { |assoc|
          "#{@model.connection.quote_table_name(assoc.join.aliased_table_name)}" + 
          ".#{@model.connection.quote_column_name(column.__name)}"
        }.join(', ')
      end
    end
    
    # Could there be more than one value related to the parent record? If so,
    # then this will return true. If not, false. It's that simple.
    #
    def is_many?
      associations.values.flatten.any? { |assoc| assoc.is_many? }
    end
  end
end