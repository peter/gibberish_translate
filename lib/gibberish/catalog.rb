module Gibberish
  class Catalog
    def self.load(locale)
      return {} if !File.exists?(file_path(locale))
      contents = IO.read(file_path(locale))
      from_lines = from_lines(contents)
      # If there are no from messages in this YAML file, default to the ones in the code instead.
      from_messages = from_lines.blank? ? Gibberish::Extractor.new.messages : YAML.load(from_lines)
      to_messages = YAML.load(contents)
      to_messages.keys.inject({}) do |hash, key|
        hash[key] = {
          :from => from_messages[key],
          :to => to_messages[key]
        }
        hash
      end
    end
    
    def self.dump(locale, messages)
      File.open(file_path(locale), "w") do |file|
        Gibberish::Extractor.cached_messages.keys.sort.each do |key|
          next if !messages[key]
          file.puts(stripped_yaml({key => messages[key][:from]}).gsub(/^/, comment_prefix))
          file.puts(stripped_yaml({key => messages[key][:to]}))
        end
      end
    end

    private
    def self.file_path(locale)
      File.join(RAILS_ROOT, "lang", "#{locale}.yml")
    end
    
    def self.comment_prefix
      "\#en: "
    end

    def self.from_lines(contents)
      contents.split(/\n/).grep(/^#{comment_prefix}/).
        map { |line| line[/^#{comment_prefix}(.*)$/, 1] }.join("\n")      
    end
    
    def self.stripped_yaml(hash)
      raw_yaml = hash.respond_to?(:ya2yaml) ? hash.ya2yaml(:syck_compatible => true) : hash.to_yaml
      raw_yaml.split(/\n/).reject { |line| line =~ /^\s*---\s*$/ }.join("\n")
    end
  end
end
