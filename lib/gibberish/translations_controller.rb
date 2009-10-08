class Gibberish::TranslationsController < ActionController::Base
  layout 'gibberish/translations'
  prepend_view_path(File.join(File.dirname(__FILE__), "..", "..", "views"))
  before_filter :set_translation_locale

  def index
    Gibberish::Extractor.flush_cache # Let's always flush, since it's fairly fast
    params[:filter] ||= "all"
    params[:page] ||= 1
    @en_messages = en_messages
    return if !translation_locale
    @translated_messages = Gibberish::Catalog.load(translation_locale)
    @keys = case params[:filter]
      when "all":
        @en_messages.keys
      when "untranslated"
        @en_messages.keys.select { |key| !@translated_messages[key] }    
      when "changed":
        @translated_messages.keys.select { |key| @translated_messages[key][:from] != @en_messages[key] }
      when "translated":
        @translated_messages.keys
      else
        raise "Unknown filter '#{@filter}'"
      end
    remove_obsolete_keys
    match_key_pattern
    match_text_pattern
    paginate_keys
  end

  def translate
    @translated_messages = Gibberish::Catalog.load(translation_locale)
    en_messages.keys.each do |key|
      if !params[key].blank?
        @translated_messages[key] ||= {}
        @translated_messages[key][:from] = en_messages[key]
        @translated_messages[key][:to] = params[key]
        if message_vars(params[key]).sort != message_vars(en_messages[key]).sort
          raise("Variable mismatch for key '#{key}': " +
            "'#{message_vars(params[key]).join(', ')}' does not match '#{message_vars(en_messages[key]).join(', ')}'")
        end
      end
    end

    Gibberish::Catalog.dump(translation_locale, @translated_messages)

    flash[:notice] = "Thanks for translating!"
    redirect_to translations_path
  end

  def reload
    Gibberish::Extractor.flush_cache

    flash[:notice] = "English messages reloaded"
    redirect_to translations_path
  end

  private
  def message_vars(message)
    message.scan(/\{\w+\}/)
  end
  
  def match_key_pattern
    return if params[:key_pattern].blank?
    @keys = @keys.select { |key| key =~ pattern_to_regexp(params[:key_pattern]) }
  end
  
  def match_text_pattern
    return if params[:text_pattern].blank?
    @keys = @keys.select do |key|
      @translated_messages[key] && @translated_messages[key][:to] =~ pattern_to_regexp(params[:text_pattern])
    end
  end
  
  def remove_obsolete_keys
    @keys = @keys.select { |key| en_messages.keys.include?(key) }
  end

  def paginate_keys
    @paginated_keys = @keys.sort[offset, per_page]
  end

  def pattern_to_regexp(pattern)
    pattern = Regexp.escape(pattern)
    pattern = pattern.include?("*") ? pattern.gsub(/\\\*/, ".*") : ".*#{pattern}.*"
    Regexp.new("^" + pattern  + "$", Regexp::IGNORECASE)
  end

  def offset
    (params[:page].to_i - 1) * per_page
  end
  helper_method :offset
  
  def per_page
    20
  end
  helper_method :per_page

  def n_pages
    1 + @keys.size/per_page
  end
  helper_method :n_pages
  
  def en_messages
    Gibberish::Extractor.cached_messages
  end

  def translation_locale
    session[:translation_locale]
  end
  helper_method :translation_locale

  def set_translation_locale
    if params[:translation_locale]
      session[:translation_locale] = params[:translation_locale]
    elsif Gibberish.languages
      session[:translation_locale] ||= Gibberish.languages.first
    end
  end
end
