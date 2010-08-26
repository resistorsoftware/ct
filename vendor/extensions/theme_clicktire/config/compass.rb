# This configuration file works with both the Compass command line tool and within Rails.
# Require any additional compass plugins here.       
require 'lemonade'
require 'fancy-buttons'
project_type = :rails
project_path = RAILS_ROOT if defined?(RAILS_ROOT)
# Set this to the root of your project when deployed:
http_path = "/"
images_dir = "public/images"
css_dir = "public/stylesheets"
sass_dir = "public/stylesheets/src"
environment = Compass::AppIntegration::Rails.env
# To enable relative paths to assets via compass helper functions. Uncomment:
relative_assets = true
