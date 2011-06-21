#
#  $Id: odbcext_mysql.rb,v 1.3 2008/04/13 22:46:09 source Exp $
#
#  OpenLink ODBC Adapter for Ruby on Rails
#  Copyright (C) 2006 OpenLink Software
#
#  Permission is hereby granted, free of charge, to any person obtaining
#  a copy of this software and associated documentation files (the
#  "Software"), to deal in the Software without restriction, including
#  without limitation the rights to use, copy, modify, merge, publish,
#  distribute, sublicense, and/or sell copies of the Software, and to
#  permit persons to whom the Software is furnished to do so, subject
#  to the following conditions:
#
#  The above copyright notice and this permission notice shall be
#  included in all copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
#  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR
#  ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
#  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
#  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
module ODBCExt
  
  # ------------------------------------------------------------------------
  # Mandatory methods
  #
  # The ODBCAdapter core doesn't not implement these methods
  
  # #last_insert_id must be implemented for any database which returns
  # false from #prefetch_primary_key?
  #
  # This method assumes that the table inserted into has a primary key defined
  # as INT AUTOINCREMENT
  def last_insert_id(table, sequence_name, stmt = nil)
    @logger.unknown("ODBCAdapter#last_insert_id>") if @trace
    select_value("select LAST_INSERT_ID()", 'last_insert_id')
  end
  
  # ------------------------------------------------------------------------
  # Optional methods
  #
  # These are supplied for a DBMS only if necessary.
  # ODBCAdapter tests for optional methods using Object#respond_to?
  
  # Pre action for ODBCAdapter#insert
  # def pre_insert(sql, name, pk, id_value, sequence_name)
  # end
  
  # Post action for ODBCAdapter#insert
  # def post_insert(sql, name, pk, id_value, sequence_name)
  # end
  
  # ------------------------------------------------------------------------
  # Method redefinitions
  #
  # DBMS specific methods which override the default implementation 
  # provided by the ODBCAdapter core.
  
  def quote_string(string)
    @logger.unknown("ODBCAdapter#quote_string>") if @trace
    
    # MySQL requires backslashes to be escaped				
    string.gsub(/\\/, '\&\&').gsub(/'/, "''")
  end
  
  def create_database(name)
    @logger.unknown("ODBCAdapter#create_database>") if @trace
    @logger.unknown("args=[#{name}]") if @trace    
    execute "CREATE DATABASE `#{name}`"
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise    
  end

  def drop_database(name)
    @logger.unknown("ODBCAdapter#drop_database>") if @trace
    @logger.unknown("args=[#{name}]") if @trace    
    execute "DROP DATABASE IF EXISTS `#{name}`"
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise    
  end
  
  def create_table(name, options = {})
    @logger.unknown("ODBCAdapter#create_table>") if @trace
    super(name, {:options => "ENGINE=InnoDB"}.merge(options))
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise
  end
  
  def rename_table(name, new_name)
    @logger.unknown("ODBCAdapter#rename_table>") if @trace
    execute "RENAME TABLE #{name} TO #{new_name}"
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise
  end
  
  def change_column(table_name, column_name, type, options = {})
    @logger.unknown("ODBCAdapter#change_column>") if @trace
    # column_name.to_s used in case column_name is a symbol
    unless options_include_default?(options)
      options[:default] = columns(table_name).find { |c| c.name == column_name.to_s }.default    
    end
    change_column_sql = "ALTER TABLE #{table_name} CHANGE #{column_name} #{column_name} #{type_to_sql(type, options[:limit], options[:precision], options[:scale])}"
    add_column_options!(change_column_sql, options)
    execute(change_column_sql)
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise  
  end

  def rename_column(table_name, column_name, new_column_name)
    @logger.unknown("ODBCAdapter#rename_column>") if @trace
    col = columns(table_name).find{ |c| c.name == column_name.to_s }
    current_type = col.sql_type
    current_type << "(#{col.limit})" if col.limit
    execute "ALTER TABLE #{table_name} CHANGE #{column_name} #{new_column_name} #{current_type}"
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise
  end
  
  def change_column_default(table_name, column_name, default)
    @logger.unknown("ODBCAdapter#change_column_default>") if @trace
    col = columns(table_name).find{ |c| c.name == column_name.to_s }
    change_column(table_name, column_name, col.type, :default => default,
      :limit => col.limit, :precision => col.precision, :scale => col.scale)
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise
  end
  
  def indexes(table_name, name = nil)
    # Skip primary key indexes
    super(table_name, name).delete_if { |i| i.unique && i.name =~ /^PRIMARY$/ }
  end

  def options_include_default?(options)
    # MySQL 5.x doesn't allow DEFAULT NULL for first timestamp column in a table
    if options.include?(:default) && options[:default].nil?
      if options.include?(:column) && options[:column].sql_type =~ /timestamp/i
        options.delete(:default)
      end
    end
    super(options)
  end
  
  def disable_referential_integrity(&block) #:nodoc:
    old = select_value("SELECT @@FOREIGN_KEY_CHECKS")
    begin
      update("SET FOREIGN_KEY_CHECKS = 0")
      yield
    ensure
      update("SET FOREIGN_KEY_CHECKS = #{old}")
    end
  end
          
  def structure_dump
    @logger.unknown("ODBCAdapter#structure_dump>") if @trace
    select_all("SHOW TABLES").inject("") do |structure, table|
      structure += select_one("SHOW CREATE TABLE #{table.to_a.first.last}")["Create Table"] + ";\n\n"
    end
  rescue Exception => e
    @logger.unknown("exception=#{e}") if @trace
    raise
  end
          
end
