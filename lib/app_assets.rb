require 'json'

module AppAssets
  MANIFEST_PATH = File.expand_path('app-assets.json', __dir__)

  module_function

  def manifest
    @manifest ||= JSON.parse(File.read(MANIFEST_PATH, encoding: 'UTF-8'))
  end

  def manifest_json
    JSON.pretty_generate(manifest)
  end

  def stylesheets
    manifest.fetch('stylesheets')
  end

  def external_scripts
    manifest.fetch('external_scripts')
  end

  def local_scripts
    manifest.fetch('local_scripts')
  end

  def css_files
    manifest.fetch('copy').fetch('css')
  end

  def js_files
    manifest.fetch('copy').fetch('js')
  end

  def vendor_files
    manifest.fetch('copy').fetch('vendor')
  end

  def root_files
    manifest.fetch('copy').fetch('root')
  end
end
