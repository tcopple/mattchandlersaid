require 'fileutils'

def create_if_missing *names
  names.each do |name|
    Dir.mkdir(name) unless File.directory?(name)
  end
end

namespace :mattchandlersaid do
  task :setup => :environment do
    data = "#{Rails.root}/data/"
    fetched = "#{data}/fetched/"
    converted = "#{data}/converted/"
    cleaned = "#{data}/cleaned/"
    loaded = "#{data}/loaded/"

    create_if_missing data, fetched, converted, cleaned, loaded
  end

  namespace :server do
    desc "start server"
    task :start => 'mattchandlersaid:setup' do
      puts "Starting #{Rails.env} listeners."

      #to avoid port collisions when the prod app is running
      port = 4000
      port += 1000 if Rails.env == 'development'
      `bundle exec this start -s5 -p #{port} -e #{Rails.env}`
    end

    desc "stop server"
    task :stop => 'mattchandlersaid:setup' do
      puts "Stopping #{Rails.env} listeners."
      port = 4000
      port += 1000 if Rails.env == 'development'
      `bundle exec this stop -s5 -p #{port} -e #{Rails.env}`
    end

    desc "restart server"
    task :restart => 'mattchandlersaid:setup' do
      Rake::Task["mattchandlersaid:server:stop"].invoke
      Rake::Task["thinking_sphinx:rebuild"].invoke
      Rake::Task["mattchandlersaid:server:start"].invoke
    end
  end

  namespace :sermons do
    desc "fetch new pdfs from thevillagechurch.com"
    task :fetch => 'mattchandlersaid:setup' do
      require 'open-uri'
      require 'net/http'

      pdfs = Dir[File.join(Rails.root, 'data', 'fetched', '*.pdf')].collect {|f| File.basename(f)}

      base = "http://www.thevillagechurch.net/ajax/ajax-resources-sermons.php?page="
      uris = Array.new

      (1..35).each do |i|
        uris << base + i.to_s
      end

      response = nil
      uris.each do |uri|
        puts "Operating on #{uri}"
        open(uri) do |file|
          response = file.read()
        end

        re = /href='(http:\/\/media.thevillagechurch.net\/sermons\/transcripts\/[^ ]*?MattChandler[^ ]*?.pdf)'/i
        response.scan(re).each do |match|
          Dir.chdir("#{Rails.root}/data/fetched/")

          # file = File.basename(match.to_s).chomp(File.extname(match.to_s)) << ".txt"
          basename = File.basename(match[0].to_s)
          found = Sermon.where(:filename => basename)

          if not found.empty?
            puts "Skipping #{basename} because it's already been loaded."
          else
            puts "Fetching #{basename}"
            `wget -nc --limit-rate=50K #{match[0]}`
          end

          Dir.chdir(Rails.root)
        end
      end
    end

    desc "convert pdf's to text files."
    task :convert => 'mattchandlersaid:setup' do
      Dir[File.join(Rails.root, 'data', 'fetched', '*.pdf')].sort.each do |pdf|
        puts "converting #{File.basename(pdf)}"

        `pdftotext #{pdf}`
        FileUtils.mv "#{pdf.chomp(File.extname(pdf))}.txt", "#{Rails.root}/data/converted/" if $? == 0
        FileUtils.rm pdf
      end
    end

    desc "clean all txt files of non printable characters"
    task :clean => 'mattchandlersaid:setup' do
      replacements = Hash.new
      replacements["'"] = "'"
      replacements[/\342\200\230/u] = "'"
      replacements[/\342\200\231/u] = "'"
      replacements[/\342\200\234/u] = '"'
      replacements[/\342\200\235/u] = '"'
      replacements[/\xe2\x80\x93/u] = '-'
      replacements[/\xe2\x80\x94/u] = '--'
      replacements[/\xe2\x80\xa6/u] = '...'

      Dir[File.join(Rails.root, 'data', 'converted', '*.txt')].sort.each do |file|
        puts "cleaning #{File.basename(file)}"

        sermon_text = nil
        File.open(file, "r") do |fh|
          sermon_text = fh.read
        end

        replacements.each do |k, v|
          sermon_text.gsub! k, v
        end

        File.open("#{Rails.root}/data/cleaned/#{File.basename(file)}", "w") do |f|
          f.write sermon_text
        end
        FileUtils.rm file
      end
    end

    desc "load txt files into database."
    task :load => 'mattchandlersaid:setup' do
      Dir[File.join(Rails.root, 'data', 'cleaned', '*.txt')].sort.each do |file|
        filename = File.basename(file, ".txt") + ".pdf"
        puts "Loading #{filename}"
        date = Date.strptime(filename.slice(0,8), "%Y%m%d")
        sermon = Sermon.to_title filename

        sermon_text = nil
        File.open(file, "r") do |fh|
          sermon_text = fh.read
        end

        if Sermon.find_by_filename(filename).nil?
          Sermon.create(:published_date => date, :title => sermon, :filename => filename, :content => sermon_text)
        end

        FileUtils.mv file, "#{Rails.root}/data/loaded/#{File.basename(file)}"
      end
    end

    desc "fetch, convert, load, and reindex for new sermons"
    task :update => 'mattchandlersaid:setup' do
      Rake::Task["mattchandlersaid:sermons:fetch"].invoke
      Rake::Task["mattchandlersaid:sermons:convert"].invoke
      Rake::Task["mattchandlersaid:sermons:clean"].invoke
      Rake::Task["mattchandlersaid:sermons:load"].invoke
      Rake::Task["thinking_sphinx:rebuild"].invoke
    end
  end
end
