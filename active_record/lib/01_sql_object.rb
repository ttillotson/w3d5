require_relative 'db_connection'
require 'active_support/inflector'
require 'byebug'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    return @columns if @columns
    rows = DBConnection.execute2(<<-SQL)
      SELECT *
      FROM #{table_name}
    SQL

    @columns = rows[0].map(&:to_sym)
  end

  def self.finalize!
    columns.each do |sym|
      # debugger
      define_method(sym.to_s) do
        attributes[sym]
      end

      define_method("#{sym}=") do |value|
        attributes[sym] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.name.underscore.pluralize
  end

  def self.all
    results_hash = DBConnection.instance.execute(<<-SQL)
      SELECT *
      FROM #{@table_name}
    SQL

    parse_all(results_hash)
    # debugger
  end

  def self.parse_all(results)
    parsed = []
    results.each do |row|
      object = self.new(row)
      parsed << object
    end

    parsed
  end

  def self.find(id)
    result = DBConnection.instance.execute(<<-SQL)
      SELECT *
      FROM #{table_name}
      WHERE #{table_name}.id = #{id}
    SQL

    return self.new(result.first) unless result.empty?
    nil
  end

  def initialize(params = {})
    params.each do |k, v|
      unless self.class.columns.include?(k.to_sym)
        raise "unknown attribute '#{k}'"
      end

      self.send("#{k}=", v)
    end

  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    # values = []
    # @columns.each do |col|
    #   col_val = DBConnection.execute(<<-SQL)
    #     SELECT #{col}
    #     FROM #{@table_name}
    #   SQL
    #   values << col_val
    # end
    #
    # values
    @attributes.values
  end

  def insert
    col_names = self.class.columns.map(&:to_s)
    question_marks = ['?'] * self.class.columns.length

    DBConnection.instance.execute(<<-SQL)
      INSERT INTO
        #{@table_name} #{col_names}
      VALUES
        #{}
    SQL

  end

  def update
    # ...
  end

  def save
    # ...
  end
end
