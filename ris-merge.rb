#! /usr/bin/env ruby

require 'optparse'

module Ris
  MULTI_VALUED = ["AU", "A2"]
  
  class RisEntry
    def initialize(enumerator)
      @properties = {}
      blank_lines = 0
      begin
        line = enumerator.next
        while true
          if line == "\n"
            blank_lines = blank_lines + 1
            if blank_lines == 2
              break
            end
          else
            key, value = line.split('  - ')
            if MULTI_VALUED.include?(key)
              current = @properties[key]
              if current
                current << value
              else
                current = [value]
                @properties[key] = current
              end
            else
              @properties[key] = value
            end
          end
          line = enumerator.next
        end
      rescue StopIteration
      end
    end
    
    def write(fp)
      @properties.each do |key, value|
        if MULTI_VALUED.include?(key)
          value.each do |v|
            fp.write("#{key}  - #{v}")
          end
        elsif not value
          fp.write(key)
        else
          fp.write("#{key}  - #{value}")
        end
      end
      fp.write("\n\n")
    end
    
    attr_reader :properties
    
    def eof?()
      @properties.empty?
    end
  end
  
  class RisMerge
	  def initialize(files, opts={})
      @files = files
      @entries = {}
      @options = opts
    end
    
    attr_reader :files, :entries
    
    def read(key_name)
      @files.each do |file|
        puts "Reading file [#{file}]" if @options[:verbose]
        enumerator = IO.foreach(file)
        while true
          entry = RisEntry.new(enumerator)
          if entry.eof?
            break
          end
          property = entry.properties[key_name]
          if property
            key = property.downcase
            key.gsub!(/[^a-zA-Z0-9\s]/, "")
            key.gsub!(/ +/, " ")
            @entries[key] = entry
          else
            puts "No property [#{key_name}] found on a record"
          end
        end
      end
    end
    
    def write(file)
      puts "Writing merged results to [#{file}]" if @options[:verbose]
      File.open(file, "w") do |fp|
        @entries.each do |key, entry|
          entry.write(fp)
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
  options = {
    :field => "TI"
  }
  OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [options] <input file(s)>"
    opts.on("-v", "--[no-]verbose", "Run verbosely") {|v| options[:verbose] = v }
    opts.on("-f", "--field field", "Field name to merge on") {|o| options[:field] = o }
    opts.on("-o", "--output output", "Output file") {|o| options[:output] = o }
    opts.on("-k", "--keyfile keyfile", "Output merged keys") {|o| options[:keyfile] = o }
  end.parse!

  ris_merge = Ris::RisMerge.new(ARGV, options)
  ris_merge.read(options[:field])
  ris_merge.write(options[:output])
  if options[:keyfile]
    ris_merge.write_keys(options[:keyfile])
  end
end
