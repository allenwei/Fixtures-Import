namespace :db_utils do
  desc "Reset database and populate with intial data. "
  task :reset_db => [:environment, 'db:migrate:reset', :import] do
  end

  desc "Populates the current environment's database with fixtures in db/fixtures folder."
  task :import => :environment do

    require 'active_record/fixtures'
    require 'rake'
    ActiveRecord::Base.establish_connection(RAILS_ENV.to_sym)

    ## set directory to import
    directory_name = ENV["DIR"] != nil ? ENV["DIR"] : 'db/fixtures'
    file_base_path = File.join(RAILS_ROOT, directory_name)
    puts "importing from: " + file_base_path

    puts "the RAILS_ENV is " + RAILS_ENV

    if ENV["TABLE"] != nil
      files_array = ENV["TABLE"].to_s.split(",")
    else
      files_array = Dir.glob(File.join(file_base_path, '*.{yml}'))
    end

    files_array.each do |fixture_file|
      puts "\n Importing " + File.basename(fixture_file.strip, ".yml") + "..."
      begin
        if fixture_file.downcase != 'schema_info'
          Fixtures.create_fixtures(file_base_path, File.basename(fixture_file.strip, '.yml'))
        else
          raise "Not willing to import schema_info!"
        end
        puts " Status: Completed"
      rescue
        puts " Status: Aborted\n\n" + $!
      end
    end
  end


  desc "Export data from tables in the current environment db to fixtures (YML format). "
  task :export => :environment do

    ## set directory to export
    file_base_path = File.join(RAILS_ROOT, 'test', "fixtures")

    puts "exporting to: " + file_base_path
    puts "the RAILS_ENV is " + RAILS_ENV

    if ENV["TABLE"] != nil
      table_names = ENV["TABLE"].to_s.split(",")
    else
      table_names = ActiveRecord::Base.connection.tables
    end

    table_names.each do |table_name|
      if table_name.downcase != 'schema_info'
        puts "\n Exporting " + table_name + "... "
        yml_file = "#{file_base_path}/#{table_name}.yml"
        i = "000000"
        File.delete(yml_file) if File.exist?(yml_file)
        File.open(yml_file, 'w' ) do |file_object|
          begin
            sql = "SELECT * FROM #{table_name}"
            data = ActiveRecord::Base.connection.select_all(sql)
            file_object.write data.inject({}) { |hash, record|
              hash["#{table_name}_#{i.succ!}"] = record
              hash
            }.to_yaml
            puts " Status: Completed"
          rescue
            puts " Status: Aborted - Table #{table_name} does not exist"
          end
        end
      end
    end
    puts "\nTask completed!"

  end


  desc "Export data from tables in the current environment db to test/fixtures/export (YML format). "
  task :export_shift => :environment do

    ## set directory to export
    file_base_path = File.join(RAILS_ROOT, 'test', "fixtures", "export")

    puts "exporting to: " + file_base_path
    puts "the RAILS_ENV is " + RAILS_ENV

    if ENV["TABLE"] != nil
      table_names = ENV["TABLE"].to_s.split(",")
    else
      table_names = ActiveRecord::Base.connection.tables
    end

    table_names.each do |table_name|
      if table_name.downcase != 'schema_info'
        puts "\n Exporting " + table_name + "... "
        yml_file = "#{file_base_path}/#{table_name}.yml"
        i = "000000"

        begin
          sql = "SELECT * FROM #{table_name}"
          data = ActiveRecord::Base.connection.select_all(sql)

          #data[x]["id"]

        rescue
          puts " Status: Aborted - Table #{table_name} does not exist"
        end

        if data.size > 0 and data.size < 100000
          File.delete(yml_file) if File.exist?(yml_file)
          File.open(yml_file, 'w' ) do |file_object|

            file_object.write data.inject({}) { |hash, record|
              hash["#{table_name}_#{i.succ!}"] = record
              hash
            }.to_yaml
            puts " Status: Completed"
          end
        end
      end
    end
    puts "\nTask completed!"

  end

end

