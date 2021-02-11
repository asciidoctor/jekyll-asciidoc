require_relative 'spec_helper'

describe 'Jekyll::AsciiDoc' do
  let :config do
    ::Jekyll.configuration fixture_site_params(name, config_path)
  end

  let :site do
    ::Jekyll::Site.new config
  end

  let :converter do
    ::Jekyll::AsciiDoc::Converter.get_instance site
  end

  let :integrator do
    ::Jekyll::AsciiDoc::Integrator.get_instance site
  end

  describe 'default configuration' do
    use_fixture :default_config

    before :each do
      site.object_id
    end

    it 'should register AsciiDoc converter' do
      (expect site.converters.any? {|c| ::Jekyll::AsciiDoc::Converter === c }).to be true
    end

    it 'should register AsciiDoc generator' do
      (expect site.generators.any? {|g| ::Jekyll::AsciiDoc::Integrator === g }).to be true
    end

    it 'should configure AsciiDoc converter to match AsciiDoc file extension' do
      (expect converter).not_to be_nil
      (expect converter.matches '.adoc').to be_truthy
    end

    it 'should use .html as output extension' do
      (expect converter).not_to be_nil
      (expect converter.output_ext '.adoc').to eql('.html')
    end

    it 'should mark configuration as configured to prevent duplicate initialization' do
      (expect (asciidoc_config = site.config['asciidoc'])).to be_a ::Jekyll::AsciiDoc::Configured
      (expect (asciidoctor_config = site.config['asciidoctor'])).to be_a ::Jekyll::AsciiDoc::Configured
      site.reset
      site.setup
      (expect site.config['asciidoc'].object_id).to eql asciidoc_config.object_id
      (expect site.config['asciidoctor'].object_id).to eql asciidoctor_config.object_id
    end

    it 'should use Asciidoctor to process AsciiDoc files by default' do
      (expect site.config['asciidoc']).to be_a ::Hash
      (expect site.config['asciidoc']['processor']).to eql 'asciidoctor'
    end

    it 'should match AsciiDoc file extensions asciidoc,adoc,ad by default' do
      (expect site.config['asciidoc']).to be_a ::Hash
      (expect site.config['asciidoc']['ext']).to eql 'asciidoc,adoc,ad'
    end

    it 'should use page- as page attribute prefix by default' do
      (expect site.config['asciidoc']).to be_a ::Hash
      (expect site.config['asciidoc']['page_attribute_prefix']).to eql 'page-'
    end

    it 'should not require a front matter header by default' do
      (expect site.config['asciidoc']).to be_a ::Hash
      (expect site.config['asciidoc']['require_front_matter_header']).to be false
    end

    it 'should use Asciidoctor in safe mode by default' do
      (expect site.config['asciidoctor']).to be_a ::Hash
      (expect site.config['asciidoctor'][:safe]).to eql 'safe'
    end

    it 'should pass implicit attributes to Asciidoctor' do
      (expect (asciidoctor_config = site.config['asciidoctor'])).to be_a ::Hash
      (expect (attrs = asciidoctor_config[:attributes])).to be_a ::Hash
      (expect attrs['env']).to eql 'site'
      (expect attrs['env-site']).to eql ''
      (expect attrs['site-gen']).to eql 'jekyll'
      (expect attrs['site-gen-jekyll']).to eql ''
      (expect attrs['builder']).to eql 'jekyll'
      (expect attrs['builder-jekyll']).to eql ''
      (expect attrs['jekyll-version']).to eql ::Jekyll::VERSION
    end

    it 'should should pass site attributes to Asciidoctor' do
      (expect (asciidoctor_config = site.config['asciidoctor'])).to be_a ::Hash
      (expect (attrs = asciidoctor_config[:attributes])).to be_a ::Hash
      (expect attrs['site-root']).to eql ::Dir.pwd
      (expect attrs['site-source']).to eql site.source
      (expect attrs['site-destination']).to eql site.dest
      (expect attrs['site-baseurl']).to eql site.config['baseurl']
      (expect attrs['site-url']).to eql 'http://example.org'
    end
  end

  describe 'legacy configuration' do
    use_fixture :legacy_config

    before :each do
      site.object_id
    end

    it 'should allow processor to be set using asciidoc key' do
      (expect site.config['asciidoc']).to be_a ::Hash
      (expect site.config['asciidoc']['processor']).to eql 'asciidoctor'
    end

    it 'should migrate asciidoc_ext key' do
      (expect site.config['asciidoc']).to be_a ::Hash
      (expect site.config['asciidoc']['ext']).to eql 'adoc'
    end

    it 'should migrate asciidoc_page_attribute_prefix key' do
      (expect site.config['asciidoc']).to be_a ::Hash
      (expect site.config['asciidoc']['page_attribute_prefix']).to eql 'jekyll-'
    end
  end

  describe 'hybrid configuration' do
    use_fixture :hybrid_config

    before :each do
      site.object_id
    end

    it 'should use new key for ext over legacy key' do
      (expect site.config['asciidoc']).to be_a ::Hash
      (expect site.config['asciidoc']['ext']).to eql 'asciidoc,adoc'
    end

    it 'should use new key page_attribute_prefix over legacy key' do
      (expect site.config['asciidoc']).to be_a ::Hash
      (expect site.config['asciidoc']['page_attribute_prefix']).to eql 'pg-'
    end
  end

  describe 'parse YAML value' do
    use_fixture :default_config

    before :each do
      site.object_id
    end

    it 'should parse string as YAML value' do
      (expect integrator.send :parse_yaml_value, '').to eql ''
      (expect integrator.send :parse_yaml_value, 'true').to be true
      (expect integrator.send :parse_yaml_value, 'false').to be false
      (expect integrator.send :parse_yaml_value, '~').to be_nil
      (expect integrator.send :parse_yaml_value, '1').to eql 1
      (expect integrator.send :parse_yaml_value, '[one, two]').to eql %w(one two)
      (expect integrator.send :parse_yaml_value, 'John\'s House').to eql 'John\'s House'
      (expect integrator.send :parse_yaml_value, '\'bar\'').to eql 'bar'
      (expect integrator.send :parse_yaml_value, '\'').to eql ?'
      (expect integrator.send :parse_yaml_value, '-').to eql '-'
      (expect integrator.send :parse_yaml_value, '@').to eql '@'
    end
  end

  describe 'imagesdir relative to root' do
    use_fixture :imagesdir_relative_to_root

    before :each do
      site.object_id
    end

    it 'should set imagesoutdir if imagesdir is relative to root' do
      (expect (asciidoctor_config = site.config['asciidoctor'])).to be_a ::Hash
      (expect (attrs = asciidoctor_config[:attributes])).to be_a ::Hash
      (expect attrs['imagesdir']).to eql '/images@'
      imagesoutdir_expected = ::File.join site.dest, (attrs['imagesdir'].chomp '@')
      (expect attrs['imagesoutdir']).to eql imagesoutdir_expected
    end
  end

  describe 'imagesdir not set' do
    use_fixture :default_config

    before :each do
      site.object_id
    end

    it 'should not set imagesoutdir if imagesdir is not set' do
      (expect (asciidoctor_config = site.config['asciidoctor'])).to be_a ::Hash
      (expect (attrs = asciidoctor_config[:attributes])).to be_a ::Hash
      (expect (attrs.key? 'imagesdir')).to be false
      (expect (attrs.key? 'imagesoutdir')).to be false
    end
  end

  describe 'compile attributes' do
    use_fixture :default_config

    before :each do
      site.object_id
    end

    it 'should assign nil value to attribute for attribute with nil value' do
      result = converter.send :compile_attributes, 'icons' => nil
      (expect (result.key? 'icons')).to be true
      (expect result['icons']).to be_nil
    end

    it 'should transform negated attribute with trailing ! to attribute with nil value' do
      result = converter.send :compile_attributes, 'icons!' => ''
      (expect (result.key? 'icons')).to be true
      (expect result['icons']).to be_nil
    end

    it 'should transform negated attribute with leading ! to attribute with nil value' do
      result = converter.send :compile_attributes, '!icons' => ''
      (expect (result.key? 'icons')).to be true
      (expect result['icons']).to be_nil
    end

    it 'should set existing attribute to nil when attribute is unset' do
      result = converter.send :compile_attributes, 'icons' => 'font', '!icons' => ''
      (expect (result.key? 'icons')).to be true
      (expect result['icons']).to be_nil
    end

    it 'should assign value to existing attribute when set again' do
      result = converter.send :compile_attributes, %w(!icons icons=font !source-highlighter source-highlighter=coderay)
      (expect result['icons']).to eql 'font'
      (expect result['source-highlighter']).to eql 'coderay'
    end

    it 'should resolve attribute references in attribute value' do
      result = converter.send :compile_attributes,
          'foo' => 'foo', 'bar' => 'bar', 'bäz' => nil, 'foobar' => '{foo}{bar}{bäz}'
      (expect result['foobar']).to eql 'foobar'
    end

    it 'should drop trailing @ from value when resolving attribute reference' do
      result = converter.send :compile_attributes,
          'foo' => 'foo@', 'bar' => 'bar@', 'baz' => '@', 'foobar' => '{foo}{bar}{baz}'
      (expect result['foobar']).to eql 'foobar'
    end

    it 'should not resolve escaped attribute reference' do
      result = converter.send :compile_attributes, 'foo' => 'foo', 'bar' => 'bar', 'foobar' => '{foo}\{bar}'
      (expect result['foobar']).to eql 'foo{bar}'
    end

    it 'should leave unresolved attribute reference in place' do
      result = converter.send :compile_attributes, 'foo' => 'foo', 'foobar' => '{foo}{bar}'
      (expect result['foobar']).to eql 'foo{bar}'
    end

    it 'should remove matching attribute if attribute starts with minus' do
      initial_attrs = { 'idseparator' => '-' }
      override_attrs = { '-idseparator' => '' }
      result = converter.send :compile_attributes, override_attrs, initial_attrs
      (expect result).to be_empty
    end

    it 'should not fail if attribute to be removed does not exist' do
      result = converter.send :compile_attributes, '-idseparator' => ''
      (expect result).to be_empty
    end

    it 'should assign empty string to attribute if value is true' do
      result = converter.send :compile_attributes, 'icons' => true
      (expect result['icons']).to eql ''
    end

    it 'should assign nil value to attribute if value is false' do
      result = converter.send :compile_attributes, 'icons' => false
      (expect (result.key? 'icons')).to be true
      (expect result['icons']).to be_nil
    end

    it 'should assign numeric value as string if value is numeric' do
      result = converter.send :compile_attributes, 'count' => 1
      (expect result['count']).to eql'1'
    end

    it 'should pass through Date value to attribute if value is Date' do
      date = ::Date.parse '2016-01-01'
      result = converter.send :compile_attributes, 'localdate' => date
      (expect result['localdate']).to eql date
    end
  end

  describe 'attributes as hash' do
    use_fixture :attributes_as_hash

    before :each do
      site.object_id
    end

    it 'should merge attributes defined as a Hash into the attributes Hash' do
      (expect (asciidoctor_config = site.config['asciidoctor'])).to be_a ::Hash
      (expect (attrs = asciidoctor_config[:attributes])).to be_a ::Hash
      (expect attrs['env']).to eql 'site'
      (expect attrs['icons']).to eql 'font'
      (expect attrs['sectanchors']).to eql ''
      (expect (attrs.key? 'table-caption')).to be true
      (expect attrs['table-caption']).to be_nil
    end
  end

  describe 'attributes as array' do
    use_fixture :attributes_as_array

    before :each do
      site.object_id
    end

    it 'should merge attributes defined as an Array into the attributes Hash' do
      (expect (asciidoctor_config = site.config['asciidoctor'])).to be_a ::Hash
      (expect (attrs = asciidoctor_config[:attributes])).to be_a ::Hash
      (expect attrs['env']).to eql 'site'
      (expect attrs['icons']).to eql 'font'
      (expect attrs['sectanchors']).to eql ''
      (expect (attrs.key? 'table-caption')).to be true
      (expect attrs['table-caption']).to be_nil
    end
  end

  describe 'alternate page attribute prefix' do
    use_fixture :alternate_page_attribute_prefix

    before :each do
      site.process
    end

    it 'should strip trailing hyphen from page attribute prefix config value' do
      (expect site.config['asciidoc']).to be_a ::Hash
      (expect site.config['asciidoc']['page_attribute_prefix']).to eql 'jekyll-'
    end

    it 'should recognize page attributes with alternate page attribute prefix' do
      page = find_page 'explicit-permalink.adoc'
      (expect page).not_to be_nil
      (expect page.permalink).to eql '/permalink/'
      file = output_file 'permalink/index.html'
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include '<div class="page-content">'
      (expect contents).not_to include %(<meta name="generator" content="Asciidoctor #{::Asciidoctor::VERSION}">)
    end
  end

  describe 'blank page attribute prefix' do
    use_fixture :blank_page_attribute_prefix

    before :each do
      site.process
    end

    it 'should coerce null value for page attribute prefix to empty string' do
      (expect site.config['asciidoc']).to be_a ::Hash
      (expect site.config['asciidoc']['page_attribute_prefix']).to eql ''
    end

    it 'should recognize page attributes with no page attribute prefix' do
      page = find_page 'explicit-permalink.adoc'
      (expect page).not_to be_nil
      (expect page.permalink).to eql '/permalink/'
      file = output_file 'permalink/index.html'
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include '<div class="page-content">'
      (expect contents).not_to include %(<meta name="generator" content="Asciidoctor #{::Asciidoctor::VERSION}">)
    end
  end

  describe 'basic site' do
    use_fixture :basic_site

    before :each do
      site.process
    end

    it 'should add an implicit YAML header to a plain AsciiDoc file' do
      file = source_file 'without-front-matter-header.adoc'
      (expect (::Jekyll::Utils.has_yaml_header? file)).to be true
    end

    it 'should convert a plain AsciiDoc file' do
      file = output_file 'without-front-matter-header.html'
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include '<p>Lorem ipsum.</p>'
    end

    it 'should promote AsciiDoc document title to page title' do
      file = output_file 'without-front-matter-header.html'
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include '<title>Page Title</title>'
    end

    it 'should convert an AsciiDoc with no doctitle or AsciiDoc header' do
      page = find_page 'no-doctitle.adoc'
      (expect page).not_to be_nil
      (expect (page.data.key? 'title')).to be false
      file = output_file 'no-doctitle.html'
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include '<title>Site Title</title>'
      (expect contents).to include %(<p>Just content.\nLorem ipsum.</p>)
    end

    it 'should convert an AsciiDoc that has an AsciiDoc header, but no doctitle' do
      page = find_page 'bare-header.adoc'
      (expect page).not_to be_nil
      (expect (page.data.key? 'title')).to be false
      (expect page.permalink).to eql '/bare/'
      file = output_file 'bare/index.html'
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include '<title>Site Title</title>'
      (expect contents).to include %(<p>Just content.\nLorem ipsum.</p>)
    end

    it 'should report an AsciiDoc file with a front matter header as having a YAML header' do
      file = source_file 'with-front-matter-header.adoc'
      (expect (::Jekyll::Utils.has_yaml_header? file)).to be true
    end

    it 'should convert an AsciiDoc file with a front matter header' do
      file = output_file 'with-front-matter-header.html'
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include '<title>Page Title</title>'
      (expect contents).to include '<p>Lorem ipsum.</p>'
    end

    it 'should convert an AsciiDoc file that has only an AsciiDoc header, no body' do
      file = output_file 'with-header-only.html'
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include '<title>Header Only</title>'
      (expect contents).to include %(<div class="page-content">\n\n</div>)
    end

    it 'should convert an AsciiDoc file that has only a front matter header, no body' do
      file = output_file 'with-front-matter-header-only.html'
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include '<title>Front Matter Only</title>'
      (expect contents).to include %(<div class="page-content">\n\n</div>)
    end

    it 'should apply explicit id and role attributes on section titles' do
      file = output_file 'section-with-id-and-role.html'
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include %(<div class="sect1 section-role">\n<h2 id="section-id">Section Title</h2>)
    end

    it 'should assign AsciiDoc document id, if set, to docid page attribute' do
      page = find_page 'docid.adoc'
      (expect page).not_to be_nil
      (expect (page.data.key? 'docid')).to be true
      (expect page.data['docid']).to eq 'page-id'
    end

    it 'should not use Liquid preprocessor by default' do
      file = output_file 'no-liquid.html'
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include '<p>{{ page.title }}</p>'
    end

    it 'should enable Liquid preprocessor if liquid page variable is set' do
      file = output_file 'liquid-enabled-front-matter.html'
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include '<p>Liquid Enabled</p>'
    end

    it 'should enable Liquid preprocessor if page-liquid page attribute is set' do
      file = output_file 'liquid-enabled-asciidoc-header.html'
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include '<p>Liquid Enabled</p>'
    end

    it 'should not publish a page if the published page variable is set in the AsciiDoc header' do
      file = output_file 'not-published.html'
      (expect ::File).not_to exist file
    end

    it 'should output a standalone HTML page if the page-layout attribute is unset' do
      file = output_file 'standalone-a.html'
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include %(<meta name="generator" content="Asciidoctor #{::Asciidoctor::VERSION}">)
      (expect contents).to include '<title>Standalone Page A</title>'
      (expect contents).to include '<h1>Standalone Page A</h1>'
    end

    it 'should output a standalone HTML page if the page-layout attribute is false' do
      file = output_file 'standalone-b.html'
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include %(<meta name="generator" content="Asciidoctor #{::Asciidoctor::VERSION}">)
      (expect contents).to include '<title>Standalone Page B</title>'
      (expect contents).to include '<h1>Standalone Page B</h1>'
    end

    it 'should apply layout named page to page content if page-layout attribute not specified' do
      file = output_file 'without-front-matter-header.html'
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include '<p>Footer for page layout.</p>'
    end

    it 'should apply layout named page to page content if page-layout attribute is empty' do
      file = output_file 'empty-layout.html'
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include '<p>Footer for page layout.</p>'
    end

    it 'should apply layout named page to page content if page-layout attribute has value _auto' do
      file = output_file 'auto-layout.html'
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include '<p>Footer for page layout.</p>'
    end

    it 'should apply specified layout to page content if page-layout has non-empty string value' do
      file = output_file 'custom-layout.html'
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include '<p>Footer for custom layout.</p>'
    end

    it 'should not apply a layout to page content if page-layout attribute is nil' do
      file = output_file 'nil-layout.html'
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include(%(div class="paragraph">\n<p>Lorem ipsum.</p>\n</div>))
    end

    it 'should convert an empty page attribute value to empty string' do
      page = find_page 'empty-page-attribute.adoc'
      (expect page).not_to be_nil
      (expect page.data['attribute-with-empty-value']).to eql ''
    end

    it 'should resolve docdir as base_dir if base_dir value is not :docdir' do
      src_file = source_file 'subdir/page-in-subdir.adoc'
      out_file = output_file 'subdir/page-in-subdir.html'
      (expect ::File).to exist out_file
      contents = ::File.read out_file
      (expect contents).to include %(docdir=#{::Dir.pwd})
      (expect contents).to include %(docfile=#{src_file})
      (expect contents).to include %(docname=#{::File.basename src_file, '.adoc'})
    end

    it 'should only register pre and post render hooks once' do
      hooks_registry = ::Jekyll::Hooks.instance_variable_get :@registry
      owned_by_plugin = proc do |hooks|
        hooks.select {|it| it.source_location[0].end_with? '/jekyll-asciidoc/converter.rb' }
      end
      (expect owned_by_plugin[hooks_registry[:pages][:pre_render]].size).to eql 1
      (expect owned_by_plugin[hooks_registry[:pages][:post_render]].size).to eql 1
      (expect owned_by_plugin[hooks_registry[:documents][:pre_render]].size).to eql 1
      (expect owned_by_plugin[hooks_registry[:documents][:post_render]].size).to eql 1
      site.process
      (expect owned_by_plugin[hooks_registry[:pages][:pre_render]].size).to eql 1
      (expect owned_by_plugin[hooks_registry[:pages][:post_render]].size).to eql 1
      (expect owned_by_plugin[hooks_registry[:documents][:pre_render]].size).to eql 1
      (expect owned_by_plugin[hooks_registry[:documents][:post_render]].size).to eql 1
    end
  end

  describe 'use site-wide standalone layout' do
    use_fixture :site_wide_standalone_layout

    before :each do
      site.process
    end

    it 'should output a standalone HTML page if the page-layout attribute is false in site config' do
      file = output_file 'standalone.html'
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include %(<meta name="generator" content="Asciidoctor #{::Asciidoctor::VERSION}">)
      (expect contents).to include '<title>Standalone Page</title>'
      (expect contents).to include '<h1>Standalone Page</h1>'
    end
  end

  describe 'use site-wide fallback layout' do
    use_fixture :site_wide_fallback_layout

    before :each do
      site.process
    end

    it 'should use layout defined in front matter if page-layout is soft set in site config' do
      file = output_file 'in-front-matter.html'
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include '<p>Footer for simple layout.</p>'
    end

    it 'should use layout defined in AsciiDoc header if page-layout is soft set in site config' do
      file = output_file 'in-asciidoc-header.html'
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include '<p>Footer for simple layout.</p>'
    end

    it 'should use layout defined in site config if not set in page' do
      file = output_file 'not-set.html'
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include '<p>Footer for default layout.</p>'
    end
  end

  describe 'explicit site time' do
    use_fixture :explicit_site_time

    before :each do
      site.process
    end

    it 'should set localdatetime on AsciiDoc pages to match site time and time zone' do
      (expect (asciidoctor_config = site.config['asciidoctor'])).to be_a ::Hash
      (expect (attrs = asciidoctor_config[:attributes])).to be_a ::Hash
      (expect attrs['localdate']).to eql (site.time.strftime '%Y-%m-%d')
      (expect attrs['localtime']).to eql (site.time.strftime '%H:%M:%S %Z')
      file = output_file 'home.html'
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include %(localdatetime=#{site.time.strftime '%Y-%m-%d %H:%M:%S %Z'})
    end
  end

  describe 'safe mode' do
    use_fixture :safe_mode

    before :each do
      site.process
    end

    it 'should register converter and generator when running in safe mode' do
      (expect site.converters.any? {|c| ::Jekyll::AsciiDoc::Converter === c }).to be true
      (expect site.generators.any? {|g| ::Jekyll::AsciiDoc::Integrator === g }).to be true
    end

    it 'should convert AsciiDoc file when running in safe mode' do
      file = output_file 'home.html'
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include '<title>Home Page</title>'
      (expect contents).to include '<p>Footer for home layout.</p>'
    end
  end

  describe 'use default as fallback layout' do
    use_fixture :fallback_to_default_layout

    before :each do
      site.process
    end

    it 'should use default layout for page if page layout is not available' do
      file = output_file 'home.html'
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include '<p>Footer for default layout.</p>'
    end

    it 'should use default layout for post if post layout is not available' do
      file = output_file '2016/01/01/post.html'
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include '<p>Footer for default layout.</p>'
    end

    it 'should use default layout for document if layout for document collection is not available' do
      file = output_file 'blueprints/blueprint.html'
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include '<p>Footer for default layout.</p>'
    end
  end

  describe 'use front matter defaults' do
    use_fixture :front_matter_defaults

    before :each do
      site.process
    end

    it 'should use the layout for the default scope when no layout is specified' do
      file = output_file 'page.html'
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include '<p>Footer for general layout.</p>'
    end

    it 'should use the layout for the matching scope when no layout is specified' do
      file = output_file 'docs/page.html'
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include '<p>Footer for docs layout.</p>'
    end
  end

  describe 'require front matter header' do
    use_fixture :require_front_matter_header

    before :each do
      site.process
    end

    it 'should consider an AsciiDoc file with a front matter header to have a YAML header' do
      file = source_file 'with-front-matter-header.adoc'
      (expect (::Jekyll::Utils.has_yaml_header? file)).to be true
    end

    it 'should not consider an AsciiDoc file without a front matter header to have a YAML header' do
      file = source_file 'without-front-matter-header.adoc'
      (expect (::Jekyll::Utils.has_yaml_header? file)).to be false
    end

    it 'should convert an AsciiDoc file with a front matter header' do
      file = output_file 'with-front-matter-header.html'
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include '<title>Page Title</title>'
      (expect contents).to include '<p>Lorem ipsum.</p>'
    end

    it 'should not convert an AsciiDoc file without a front matter header' do
      file = output_file 'without-front-matter-header.adoc'
      (expect ::File).to exist file
    end
  end

  describe 'site with posts' do
    use_fixture :with_posts

    before :each do
      site.show_drafts = true
      site.process
    end

    it 'should use document title as post title' do
      post = find_post '2016-01-01-welcome.adoc'
      (expect post).not_to be_nil
      (expect post.data['title']).to eql 'Welcome, Visitor!'
      file = output_file '2016/01/01/welcome.html'
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include '<title>Welcome, Visitor!</title>'
      (expect contents).not_to include '<h1>Welcome, Visitor!</h1>'
    end

    it 'should use automatic title if no document title is given' do
      post = find_post '2016-05-31-automatic-title.adoc'
      (expect post).not_to be_nil
      (expect post.data['title']).to eql 'Automatic Title'
      file = output_file '2016/05/31/automatic-title.html'
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include '<title>Automatic Title</title>'
    end

    it 'should set author of post to value defined in AsciiDoc header' do
      post = find_post '2016-01-01-welcome.adoc'
      (expect post).not_to be_nil
      (expect post.data['author']).to eql 'Henry Jekyll'
    end

    it 'should apply layout named post to post content if page-layout attribute not specified' do
      file = output_file '2016/01/01/welcome.html'
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include '<p>Footer for post layout.</p>'
    end

    it 'should apply layout named post to post content if page-layout attribute is empty' do
      file = output_file '2016/01/02/empty-layout.html'
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include '<p>Footer for post layout.</p>'
    end

    it 'should apply layout named post to post content if page-layout attribute has value _auto' do
      file = output_file '2016/01/03/auto-layout.html'
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include '<p>Footer for post layout.</p>'
    end

    it 'should apply custom layout to post content if page-layout attribute has non-empty string value' do
      file = output_file '2016/01/04/custom-layout.html'
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include '<p>Footer for custom layout.</p>'
    end

    it 'should not apply a layout to post content if page-layout attribute is nil' do
      file = output_file '2016/01/05/nil-layout.html'
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include %(div class="paragraph">\n<p>Lorem ipsum.</p>\n</div>)
    end

    it 'should show the title above the content if the showtitle attribute is set' do
      file = output_file '2016/04/01/show-me-the-title.html'
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include '<title>Show Me the Title</title>'
      (expect contents).to include '<h1 class="post-title">Show Me the Title</h1>'
      (expect contents).to include '<h1>Show Me the Title</h1>'
    end

    it 'should interpret value of page attribute as YAML data' do
      post = find_post '2016-02-01-post-with-categories.adoc'
      (expect post).not_to be_nil
      (expect post.data['categories']).to eql %w(code javascript)
      file = output_file 'code/javascript/2016/02/01/post-with-categories.html'
      (expect ::File).to exist file
    end

    it 'should merge singular variables with collection variables' do
      post = find_post '2016-02-02-post-with-singular-vars.adoc'
      (expect post).not_to be_nil
      (expect post.data['category']).to eql 'code'
      (expect post.data['categories']).to eql %w(code node javascript)
      (expect post.data['tag']).to eql 'syntax'
      (expect post.data['tags']).to eql %w(syntax tip beginner)
      file = output_file 'code/node/javascript/2016/02/02/post-with-singular-vars.html'
      (expect ::File).to exist file
    end

    it 'should convert revdate to local Time object and use it as date of post' do
      # NOTE Time.parse without time zone assumes time zone of site
      date = ::Time.parse '2016-06-15 10:30:00'
      date = date.localtime
      slug = 'post-with-date'
      post = find_post %(#{date.strftime '%Y-%m-%d'}-#{slug}.adoc)
      (expect post).not_to be_nil
      (expect post.data['date']).to be_a ::Time
      (expect post.data['date'].to_s).to eql date.to_s
      file = output_file %(#{date.strftime '%Y/%m/%d'}/#{slug}.html)
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include [
        %(<time class="date-published" datetime="#{date.xmlschema}">),
        (date.strftime '%B %d, %Y'),
        '</time>',
      ].join
    end

    it 'should convert revdate with time zone to local Time object and use it as date of post' do
      date = ::Time.parse '2016-07-15 04:15:30 -0600'
      date = date.localtime
      slug = 'post-with-date-and-tz'
      post = find_post %(#{date.strftime '%Y-%m-%d'}-#{slug}.adoc)
      (expect post).not_to be_nil
      (expect post.data['date']).to be_a ::Time
      (expect post.data['date'].to_s).to eql date.to_s
      file = output_file %(#{date.strftime '%Y/%m/%d'}/#{slug}.html)
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include [
        %(<time class="date-published" datetime="#{date.xmlschema}">),
        (date.strftime '%B %d, %Y'),
        '</time>',
      ].join
    end

    it 'should convert revdate in revision line to local Time object and use it as date of post' do
      date = ::Time.parse '2016-07-20 05:45:25 -0600'
      date = date.localtime
      slug = 'post-with-date-in-revision-line'
      post = find_post %(#{date.strftime '%Y-%m-%d'}-#{slug}.adoc)
      (expect post).not_to be_nil
      (expect post.data['date']).to be_a ::Time
      (expect post.data['date'].to_s).to eql date.to_s
      file = output_file %(#{date.strftime '%Y/%m/%d'}/#{slug}.html)
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include [
        %(<time class="date-published" datetime="#{date.xmlschema}">),
        (date.strftime '%B %d, %Y'),
        '</time>',
      ].join
    end

    it 'should process AsciiDoc header of draft post' do
      draft = find_draft 'a-draft-post.adoc'
      (expect draft).not_to be_nil
      (expect draft.data['author']).to eql 'Henry Jekyll'
      (expect draft.data['tags']).to eql ['draft']
      file = output_file %(#{draft.date.strftime '%Y/%m/%d'}/a-draft-post.html)
      (expect ::File).to exist file
    end

    it 'should convert excerpt from AsciiDoc using site-wide doctype' do
      file = output_file 'index.html'
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include '<div class="excerpt">This is the <em>excerpt</em> of this post.</div>'
    end

    it 'should convert excerpt from AsciiDoc using page-specific doctype' do
      file = output_file 'index.html'
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include %(<div class="paragraph">\n<p>Lorem ipsum.</p>\n</div>)
    end
  end

  describe 'posts with excerpts' do
    [:plain, :with_plugin].each do |config_path|
      use_fixture :posts_with_excerpts, config_path

      before :each do
        site.process
      end

      it 'should use page contents as excerpt if excerpt separator not found after AsciiDoc header' do
        file = output_file 'index.html'
        (expect ::File).to exist file
        contents = ::File.read file
        contents =~ %r/<li data-slug="header-and-single-paragraph">(.*?)<\/li>/m
        (expect $1).to include '<p>This is the excerpt and body text.</p>'
      end

      it 'should use first paragraph as excerpt if excerpt separator is found after AsciiDoc header' do
        file = output_file 'index.html'
        (expect ::File).to exist file
        contents = ::File.read file
        contents =~ %r/<li data-slug="header-and-multiple-paragraphs">(.*?)<\/li>/m
        (expect $1).to include '<p>This is the excerpt.</p>'
        (expect $1).not_to include '<p>This is the rest of the body text that comes after the excerpt.</p>'
      end

      it 'should use page contents as excerpt if excerpt separator not found with no AsciiDoc header' do
        file = output_file 'index.html'
        (expect ::File).to exist file
        contents = ::File.read file
        contents =~ %r/<li data-slug="single-paragraph-only">(.*?)<\/li>/m
        (expect $1).to include '<p>This is the excerpt and body text.</p>'
      end

      it 'should use first paragraph as excerpt if excerpt separator is found with no AsciiDoc header' do
        file = output_file 'index.html'
        (expect ::File).to exist file
        contents = ::File.read file
        contents =~ %r/<li data-slug="multiple-paragraphs-only">(.*?)<\/li>/m
        (expect $1).to include '<p>This is the <em>excerpt</em>.</p>'
        (expect $1).not_to include '<p>This is the rest of the body text that comes after the excerpt.</p>'
      end

      it 'should use excerpt defined as page attribute in AsciiDoc header' do
        file = output_file 'index.html'
        (expect ::File).to exist file
        contents = ::File.read file
        contents =~ %r/<li data-slug="excerpt-in-header">(.*?)<\/li>/m
        (expect $1).to include '<p>This is the <em>excerpt</em>.</p>'
        (expect $1).not_to include '<p>This is the first paragraph, but not the excerpt.</p>'
      end

      it 'should use excerpt defined in front matter' do
        file = output_file 'index.html'
        (expect ::File).to exist file
        contents = ::File.read file
        contents =~ %r/<li data-slug="excerpt-in-front-matter">(.*?)<\/li>/m
        (expect $1).to include '<p>This is the <em>excerpt</em>.</p>'
        (expect $1).not_to include '<p>This is the first paragraph, but not the excerpt.</p>'
      end

      it 'should set excerpt to blank if excerpt_separator is blank' do
        file = output_file 'index.html'
        (expect ::File).to exist file
        contents = ::File.read file
        contents =~ %r/<li data-slug="blank-excerpt">(.*?)<\/li>/m
        (expect $1).to include '<p class="excerpt"></p>'
      end

      it 'should set excerpt to blank if document only has a header' do
        file = output_file 'index.html'
        (expect ::File).to exist file
        contents = ::File.read file
        contents =~ %r/<li data-slug="header-only">(.*?)<\/li>/m
        (expect $1).to include '<p class="excerpt"></p>'
      end

      it 'should not process liquid in excerpt by default' do
        file = output_file 'index.html'
        (expect ::File).to exist file
        contents = ::File.read file
        contents =~ %r/<li data-slug="no-liquid">(.*?)<\/li>/m
        (expect $1).to include '<p>{{ page.title }}</p>'
      end

      it 'should process liquid in excerpt if liquid page variable is set' do
        file = output_file 'index.html'
        (expect ::File).to exist file
        contents = ::File.read file
        contents =~ %r/<li data-slug="with-liquid">(.*?)<\/li>/m
        (expect $1).to include '<p>With Liquid</p>'
      end

      it 'should extract excerpt correctly even when post uses standalone layout' do
        file = output_file 'index.html'
        (expect ::File).to exist file
        contents = ::File.read file
        contents =~ %r/<li data-slug="standalone-layout">(.*?)<\/li>/m
        (expect $1).to include '<p>Excerpt of post with standalone layout.</p>'
        (expect $1).not_to include '<p>This is not part of the excerpt.</p>'
      end
    end
  end

  describe 'custom excerpt separator' do
    use_fixture :custom_excerpt_separator

    before :each do
      site.process
    end

    it 'should use excerpt_separator for markdown posts' do
      file = output_file 'index.html'
      (expect ::File).to exist file
      contents = ::File.read file
      contents =~ %r/<li data-slug="markdown">(.*?)<\/li>/m
      (expect $1).to include 'This is also part of the excerpt'
      (expect $1).not_to include 'This is not part of the excerpt'
    end

    it 'should use page-excerpt_separator for AsciiDoc posts' do
      file = output_file 'index.html'
      (expect ::File).to exist file
      contents = ::File.read file
      contents =~ %r/<li data-slug="asciidoc">(.*?)<\/li>/m
      (expect $1).to include 'This is also part of the excerpt'
      (expect $1).not_to include 'This is not part of the excerpt'
    end
  end

  describe 'read error' do
    use_fixture :read_error

    before :each do
      ::File.chmod 0o0000, (source_file 'unreadable.adoc')
      site.process
    end

    after :each do
      ::File.chmod 0o0664, (source_file 'unreadable.adoc')
    end

    it 'should not fail when file cannot be read' do
      file = output_file 'unreadable.html'
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to be_empty
    end
  end unless windows?

  describe 'site with include relative to docdir' do
    use_fixture :include_relative_to_docdir

    before :each do
      site.process
    end

    it 'should not expand base_dir when base_dir config key has value :docdir' do
      (expect site.config['asciidoctor'][:base_dir]).to eql :docdir
    end

    it 'should resolve include relative to docdir when base_dir config key has value :docdir' do
      src_file = source_file 'about/index.adoc'
      out_file = output_file 'about/index.html'
      (expect ::File).to exist out_file
      contents = ::File.read out_file
      (expect contents).to include 'Doc Writer'
      (expect contents).to include %(docfile=#{src_file})
      (expect contents).to include %(docdir=#{::File.dirname src_file})
      (expect contents).to include %(outfile=#{out_file})
      (expect contents).to include %(outdir=#{::File.dirname out_file})
      (expect contents).to include %(outpath=/about/)
    end

    it 'should resolve attribute defined in included file' do
      file = output_file 'parent.html'
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include '<p>value</p>'
    end
  end

  describe 'site with include relative to root' do
    use_fixture :include_relative_to_root

    let :config do
      (::Jekyll.configuration fixture_site_params name).merge('source' => (::File.join (source_dir name), 'source'))
    end

    before :each do
      @old_pwd = ::Dir.pwd
      ::Dir.chdir source_dir name
      site.process
    end

    after :each do
      ::Dir.chdir @old_pwd
    end

    it 'should not set base_dir if base_dir config key has no value' do
      (expect (site.config['asciidoctor'].key? :base_dir)).to be false
    end

    it 'should resolve include relative to root when base_dir is not set' do
      src_file = source_file 'about/index.adoc'
      out_file = output_file 'about/index.html'
      (expect ::File).to exist out_file
      contents = ::File.read out_file
      (expect contents).to include 'Doc Writer'
      (expect contents).to include %(docdir=#{::Dir.pwd})
      (expect contents).to include %(docfile=#{src_file})
      (expect contents).to include %(outfile=#{out_file})
      (expect contents).to include %(outdir=#{::File.dirname out_file})
      (expect contents).to include %(outpath=/about/)
    end
  end

  describe 'site with include relative to source' do
    use_fixture :include_relative_to_source

    before :each do
      site.process
    end

    it 'should expand base_dir to match site source when base_dir config key has value :source' do
      (expect site.config['asciidoctor'][:base_dir]).to eql site.source
    end

    it 'should resolve include relative to source when base_dir config key has value :source' do
      src_file = source_file 'about/index.adoc'
      out_file = output_file 'about/index.html'
      (expect ::File).to exist out_file
      contents = ::File.read out_file
      (expect contents).to include 'Doc Writer'
      (expect contents).to include %(docdir=#{site.source})
      (expect contents).to include %(docfile=#{src_file})
      (expect contents).to include %(outfile=#{out_file})
      (expect contents).to include %(outdir=#{::File.dirname out_file})
      (expect contents).to include %(outpath=/about/)
    end

    it 'should not process file that begins with an underscore' do
      file = output_file 'about/_people.html'
      (expect ::File).not_to exist file
    end
  end

  describe 'site with custom collection' do
    use_fixture :with_custom_collection

    before :each do
      site.process
    end

    it 'should decorate document in custom collection' do
      doc = find_doc 'blueprint-a.adoc', 'blueprints'
      (expect doc).not_to be_nil
      (expect doc.data['title']).to eql 'First Blueprint'
      (expect doc.data['date']).to be_a ::Time
      (expect doc.data['date'].strftime '%Y-%m-%d').to eql '2018-01-01'
      (expect doc.data['foo']).to eql 'bar'
    end

    it 'should select layout that is based on the collection label by default' do
      file = output_file 'blueprints/blueprint-a.html'
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include '<p>Footer for blueprint layout.</p>'
    end

    it 'should allow the layout to be customized' do
      file = output_file 'blueprints/blueprint-b.html'
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include '<p>Footer for default layout.</p>'
    end

    it 'should set docdir for document in custom collection when base_dir config key has the value :docdir' do
      src_file = source_file '_blueprints/blueprint-b.adoc'
      out_file = output_file 'blueprints/blueprint-b.html'
      (expect ::File).to exist out_file
      contents = ::File.read out_file
      (expect contents).to include %(docfile=#{src_file})
      (expect contents).to include %(docdir=#{::File.dirname src_file})
      (expect contents).to include %(outfile=#{out_file})
      (expect contents).to include %(outdir=#{::File.dirname out_file})
      (expect contents).to include %(outpath=/blueprints/blueprint-b.html)
    end
  end

  describe 'site with custom private collection' do
    use_fixture :with_custom_private_collection

    before :each do
      site.process
    end

    it 'should integrate pages in collection even when collection is not written' do
      current_branch_file = output_file 'tips/current-branch.html'
      (expect ::File).not_to exist current_branch_file
      index_file = output_file 'index.html'
      (expect ::File).to exist index_file
      index_contents = ::File.read index_file
      (expect index_contents).to include '<h1>Current Branch</h1>'
      (expect index_contents).to include '<h2>Language: git</h2>'
      (expect index_contents).to include '<h1>Needle In Haystack</h1>'
      (expect index_contents).to include '<h2>Language: js</h2>'
    end
  end

  describe 'pygments code highlighting' do
    use_fixture :pygments_code_highlighting

    before :each do
      ::Jekyll::StaticFile.reset_cache
      site.process
    end

    it 'should write the pygments stylesheet to the stylesdir' do
      src_file = source_file 'css/asciidoc-pygments.css'
      out_file = output_file 'css/asciidoc-pygments.css'
      begin
        (expect ::File).to exist src_file
        (expect ::File).to exist out_file
        src_content = ::File.read src_file
        out_content = ::File.read out_file
        (expect src_content).to eql out_content
        (expect src_content).to include '.pygments .tok-c'
      ensure
        if ::File.exist? src_file
          ::File.delete src_file
          ::Dir.rmdir ::File.dirname src_file
        end
      end
    end

    it 'should overwrite pygments stylesheet if style has changed' do
      src_file = source_file 'css/asciidoc-pygments.css'
      out_file = output_file 'css/asciidoc-pygments.css'
      begin
        src_content = ::File.read src_file
        out_content = ::File.read src_file
        attrs = site.config['asciidoctor'][:attributes]
        attrs['pygments-style'] = 'monokai'
        integrator.generate_pygments_stylesheet site, attrs
        (expect ::File.read src_file).not_to eql src_content
        ::Jekyll::StaticFile.reset_cache
        site.process
        new_out_content = ::File.read out_file
        (expect new_out_content).not_to eql out_content
        (expect new_out_content).to include 'background-color: #49483e'
      ensure
        if ::File.exist? src_file
          ::File.delete src_file
          ::Dir.rmdir ::File.dirname src_file
        end
      end
    end
  end

  describe 'xhtml syntax' do
    use_fixture :xhtml_syntax

    before :each do
      site.process
    end

    it 'should output xhtml if asciidoctor backend option is xhtml' do
      file = output_file 'home.html'
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include '<img src="/images/sunset.jpg" alt="Sunset" width="408" height="230"/>'
    end
  end

  describe 'asciidocify filter' do
    use_fixture :asciidocify_filter

    before :each do
      site.process
    end

    it 'should run content through asciidocify filter using specified doctype' do
      file = output_file 'index.html'
      (expect ::File).to exist file
      contents = ::File.read file
      (expect contents).to include '<p class="summary">A <strong>very</strong> welcoming <em>welcome</em> page.</p>'
    end
  end

  describe 'tocify filter' do
    use_fixture :tocify_filter

    before :each do
      site.process
    end

    it 'should generate document outline when tocify_asciidoc filter is applied to page.document' do
      file = output_file 'index.html'
      (expect ::File).to exist file
      contents = ::File.read file
      aside = (contents.match %r/<aside class="page-toc">.*<\/aside>/m)[0]
      (expect aside).to include '<ul class="sectlevel1">'
      (expect aside).to include '<a href="#major-section-a">Major Section A</a>'
      (expect aside).not_to include 'Micro Section'
    end
  end

  describe 'docinfo filter' do
    use_fixture :docinfo_filter

    before :each do
      site.process
    end

    it 'should include docinfo content when docinfo filter is applied to page.document' do
      file = output_file 'index.html'
      (expect ::File).to exist file
      contents = ::File.read file
      head = (contents.match %r/<head>.*<\/head>/m)[0]
      (expect head).to include '<div>this is the head</div>'
      (expect header_loc = contents.index('<header>this is the header</header>')).to be > contents.index(head)
      (expect custom_loc = contents.index('<div class="custom">this is custom</div>')).to be > header_loc
      (expect contents.index('<footer>this is the footer</footer>')).to be > custom_loc
    end
  end
end
