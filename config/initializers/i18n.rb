# http://svenfuchs.com/2011/2/11/organizing-translations-with-i18n-cascade-and-i18n-missingtranslations
I18n::Backend::Simple.send(:include, I18n::Backend::Cascade)

ActionView::Base.class_eval do
  def translate(key, options = {})
    super(key, options.merge(cascade: true))
  end
  alias t translate
end
