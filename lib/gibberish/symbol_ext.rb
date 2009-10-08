class Symbol
  def l(*args)
    default_text = Gibberish::Extractor.cached_messages[self]
    raise "Could not find default text for key '#{self}'" if !default_text
    Gibberish.translate(default_text, self, *args)
  end
end
