#! /usr/bin/env ruby

require 'optparse'

module Ris
  NEW_LINE = ["\r\n", "\n"]
  
  class RisEntry
    def initialize(enumerator)
      @properties = {}
      key = nil

      while true
        line = enumerator.next
        if NEW_LINE.include?(line)
          next
        else
          match = /([A-Z][A-Z0-9])  - (.*)/m.match(line)
          if match
            key = match[1]
            value = match[2]
            value.gsub!(/\r\n/, "\n")

            if 'ER' == key
              break
            else
              current = @properties[key]
              if current
                current << value
              else
                @properties[key] = [value]
              end
            end
          else
            # multi line
            @properties[key].last << line
          end
        end
      end
      @properties.freeze
    end
    
    def write(fp)
      @properties.each do |key, value|
        value.each do |v|
          fp.write("#{key}  - #{v}")
        end
      end
      fp.write("ER  - \n\n")
    end
    
    attr_reader :properties
  end
  
  class RisMerge
    def initialize(opts={})
      @entries = {}
      @options = opts
      @options[:fields] ||= ["TI"]
    end
    
    attr_reader :files, :entries, :input_count
    
    def read(files)
      @input_count = 0
      files.each do |file|
        puts "Reading file [#{file}]" if @options[:verbose]
        enumerator = IO.foreach(file)
        count = 0
        while true
          begin
            entry = RisEntry.new(enumerator)
            property = nil
            @options[:fields].each do |field|
              property = entry.properties[field]
              break if property
            end
            if property and property.first
              key = property.first.downcase
              key.gsub!(/[^a-zA-Z0-9\s]/, "")
              key.gsub!(/ +/, " ")
              @entries[key] = entry
              count += 1
            else
              puts "No property [#{@options[:fields]}] found on a record"
              p entry.properties
            end
          rescue StopIteration
            break
          end
        end
        @input_count += count
        puts "  records [#{count}]" if @options[:verbose]
      end
    end

    def create_filename(file, count)
      file_dirname = File.dirname(file)
      file_basename = File.basename(file, '.*')
      file_extension = File.extname(file)
      File.join(file_dirname, "#{file_basename}-#{count}#{file_extension}")
    end
    
    def write(file, chunk_size)
      if @options[:verbose]
        puts "Writing merged results to [#{file}]" 
        delta = @entries.count - @input_count
        puts "  input=[#{@input_count}] output=[#{@entries.count}] delta=[#{delta}] delta%=[#{100.0 * delta / @input_count}]"
      end
      if chunk_size
        count = 0
        file_count = 0
        fp = File.open(create_filename(file, file_count), "w")
        @entries.each do |key, entry|
          count = count + 1
          if count == chunk_size
            count = 0
            file_count = file_count + 1
            fp.close()
            fp = File.open(create_filename(file, file_count), "w")
          end
          entry.write(fp)
        end

        fp.close()
      else
        File.open(file, "w") do |fp|
          @entries.each do |key, entry|
            entry.write(fp)
          end
        end
      end
    end

    def write_keys(file)
      puts "Writing keys to [#{file}]" if @options[:verbose]
      File.open(file, "w") do |fp|
        @entries.keys.sort.each do |key|
          fp.write(key)
        end
      end
    end
  
  end
end

if __FILE__ == $0
  options = {}
  OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [options] <input file(s)>"
    opts.on("-v", "--[no-]verbose", "Run verbosely") {|v| options[:verbose] = v }
    opts.on("-f", "--field field", "Field name to merge on") {|o| (options[:fields] ||= [] ) << o }
    opts.on("-o", "--output output", "Output file") {|o| options[:output] = o }
    opts.on("-c", "--chunked count", "Output should be chunked") {|o| options[:chunked] = o.to_i }
    opts.on("-k", "--keyfile keyfile", "Output merged keys") {|o| options[:keyfile] = o }
  end.parse!
  files = ARGV

  ris_merge = Ris::RisMerge.new(options)

  ris_merge.read(files)

  if options[:output]
    ris_merge.write(options[:output], options[:chunked])
  end

  if options[:keyfile]
    ris_merge.write_keys(options[:keyfile])
  end
end
