module Gibberish
  class Routes
    def self.translation_ui(map)
      map.with_options(:controller => 'gibberish/translations') do |m|
        m.translations '/translations'
        m.translate '/translations/translate', :action => 'translate'
        m.translations_reload '/translations/reload', :action => 'reload'
      end
    end
  end
end
