require 'spree/extension'

all_locale_paths = Spree::ExtensionLoader.load_extension_roots.dup << RAILS_ROOT

AVAILABLE_LOCALES = {}

all_locale_paths.each do |path|
	path = File.join(path, 'config', 'locales')
	if File.exists? path
		locales = Dir.new(path).entries.collect do |x|
		  x =~ /^[^\.].+\.yml$/ ? x.sub(/\.yml/,"") : nil
		end.compact.each_with_object({}) do |str, hsh|      
		  locale_file = YAML.load_file(path + "/" + str + ".yml")
		  str = str.gsub("_spree", "")
		  hsh[str] = locale_file[str]["this_file_language"] if locale_file.has_key? str
		end.freeze
		AVAILABLE_LOCALES.merge! locales
	end
	
	
end


# D. Lazar had to do this to remove all the crappy other Localization files.. and not pollute the language bar with tons of flags...
AVAILABLE_LOCALES.delete_if {|k,| !k.match(/^(fr\-FR|en\-CA)/) } 
