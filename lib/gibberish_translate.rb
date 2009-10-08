%w(extractor translations_controller translations_helper symbol_ext).each do |file|
  require File.join(File.dirname(__FILE__), "gibberish", file)
end
