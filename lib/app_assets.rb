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

  def minify_css(css)
    minified = strip_css_comments(css)
    protected_segments = []

    minified = protect_css_literals(minified, protected_segments)
    minified = minified.gsub(/\s+/, ' ')
                       .strip
                       .gsub(/\s*([{};,>])\s*/, '\1')
                       .gsub(/;}/, '}')
    minified = restore_css_literals(minified, protected_segments)

    return css unless css.count('{') == minified.count('{') && css.count('}') == minified.count('}')

    minified
  rescue StandardError
    css
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

  def strip_css_comments(css)
    output = +''
    i = 0

    while i < css.length
      char = css[i]

      if char == '"' || char == "'"
        literal, i = read_css_string(css, i)
        output << literal
      elsif css[i, 2] == '/*'
        comment_end = css.index('*/', i + 2)
        return css unless comment_end

        i = comment_end + 2
      else
        output << char
        i += 1
      end
    end

    output
  end

  def protect_css_literals(css, protected_segments)
    output = +''
    i = 0

    while i < css.length
      char = css[i]

      if char == '"' || char == "'"
        literal, i = read_css_string(css, i)
        output << css_literal_placeholder(literal, protected_segments)
      elsif css[i, 16].match?(/\Aurl\s*\(/i)
        literal, i = read_css_function(css, i)
        output << css_literal_placeholder(literal, protected_segments)
      else
        output << char
        i += 1
      end
    end

    output
  end

  def restore_css_literals(css, protected_segments)
    protected_segments.each_with_index do |segment, index|
      css = css.gsub(css_placeholder(index), segment)
    end
    css
  end

  def css_literal_placeholder(literal, protected_segments)
    protected_segments << literal
    css_placeholder(protected_segments.length - 1)
  end

  def css_placeholder(index)
    "__CSS_LITERAL_#{index}__"
  end

  def read_css_string(css, start_index)
    quote = css[start_index]
    i = start_index + 1

    while i < css.length
      if css[i] == '\\'
        i += 2
      elsif css[i] == quote
        i += 1
        break
      else
        i += 1
      end
    end

    [css[start_index...i], i]
  end

  def read_css_function(css, start_index)
    open_paren = css.index('(', start_index)
    return [css[start_index], start_index + 1] unless open_paren

    i = open_paren + 1
    depth = 1

    while i < css.length
      char = css[i]

      if char == '"' || char == "'"
        _literal, i = read_css_string(css, i)
      elsif char == '\\'
        i += 2
      elsif char == '('
        depth += 1
        i += 1
      elsif char == ')'
        depth -= 1
        i += 1
        break if depth.zero?
      else
        i += 1
      end
    end

    [css[start_index...i], i]
  end
end
