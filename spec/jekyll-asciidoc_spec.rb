require 'spec_helper'

describe(Jekyll::AsciiDoc) do
  let(:config) do
    Jekyll.configuration(fixture_site_params(name))
  end

  let(:site) do
    Jekyll::Site.new(config)
  end

  describe('default configuration') do
    let(:name) do
      'default_config'
    end

    it 'should register AsciiDoc converter' do
      expect(site.converters.any? {|c| Jekyll::Converters::AsciiDocConverter === c }).to be true
    end

    it 'should register AsciiDoc generator' do
      expect(site.generators.any? {|g| Jekyll::Generators::AsciiDocPreprocessor === g }).to be true
    end

    it 'should configure AsciiDoc converter to match AsciiDoc file extension' do
      converter = site.converters.find {|c| Jekyll::Converters::AsciiDocConverter === c }
      expect(converter).not_to be_nil
      expect(converter.matches('.adoc')).to be_truthy
    end

    it 'should use .html as output extension' do
      converter = site.converters.find {|c| Jekyll::Converters::AsciiDocConverter === c }
      expect(converter).not_to be_nil
      expect(converter.output_ext('.adoc')).to eql ('.html')
    end

    it 'should use Asciidoctor to process AsciiDoc files by default' do
      expect(site.config['asciidoc']).to be_a(Hash)
      expect(site.config['asciidoc']['processor']).to eql('asciidoctor')
    end

    it 'should match AsciiDoc file extensions asciidoc,adoc,ad by default' do
      expect(site.config['asciidoc']).to be_a(Hash)
      expect(site.config['asciidoc']['ext']).to eql('asciidoc,adoc,ad')
    end

    it 'should use page as page attribute prefix by default' do
      expect(site.config['asciidoc']).to be_a(Hash)
      expect(site.config['asciidoc']['page_attribute_prefix']).to eql('page')
    end

    it 'should not require a front matter header by default' do
      expect(site.config['asciidoc']).to be_a(Hash)
      expect(site.config['asciidoc']['require_front_matter_header']).to be false
    end

    it 'should use Asciidoctor in safe mode by default' do
      expect(site.config['asciidoctor']).to be_a(Hash)
      expect(site.config['asciidoctor'][:safe]).to eql('safe')
    end

    it 'should pass implicit attributes to Asciidoctor by default' do
      expect(site.config['asciidoctor']).to be_a(Hash)
      expect(site.config['asciidoctor'][:attributes]).to be_a(Hash)
      expect(site.config['asciidoctor'][:attributes]['env']).to eql('site')
      expect(site.config['asciidoctor'][:attributes]['env-site']).to eql('')
      expect(site.config['asciidoctor'][:attributes]['site-gen']).to eql('jekyll')
      expect(site.config['asciidoctor'][:attributes]['site-gen-jekyll']).to eql('')
      expect(site.config['asciidoctor'][:attributes]['builder']).to eql('jekyll')
      expect(site.config['asciidoctor'][:attributes]['builder-jekyll']).to eql('')
      expect(site.config['asciidoctor'][:attributes]['jekyll-version']).to eql(Jekyll::VERSION)
    end
  end

  describe('legacy configuration') do
    let(:name) do
      'legacy_config'
    end

    it 'should allow processor to be set using asciidoc key' do
      expect(site.config['asciidoc']).to be_a(Hash)
      expect(site.config['asciidoc']['processor']).to eql('asciidoctor')
    end

    it 'should migrate asciidoc_ext key' do
      expect(site.config['asciidoc']).to be_a(Hash)
      expect(site.config['asciidoc']['ext']).to eql('adoc')
    end

    it 'should migrate asciidoc_page_attribute_prefix key' do
      expect(site.config['asciidoc']).to be_a(Hash)
      expect(site.config['asciidoc']['page_attribute_prefix']).to eql('jekyll')
    end
  end

  describe('hybrid configuration') do
    let(:name) do
      'hybrid_config'
    end

    it 'should use new key for ext over legacy key' do
      expect(site.config['asciidoc']).to be_a(Hash)
      expect(site.config['asciidoc']['ext']).to eql('asciidoc,adoc')
    end

    it 'should use new key page_attribute_prefix over legacy key' do
      expect(site.config['asciidoc']).to be_a(Hash)
      expect(site.config['asciidoc']['page_attribute_prefix']).to eql('pg')
    end
  end

  describe('attributes as hash') do
    let(:name) do
      'attributes_as_hash'
    end

    it 'should merge attributes defined as a Hash into the attributes Hash' do
      expect(site.config['asciidoctor']).to be_a(Hash)
      expect(site.config['asciidoctor'][:attributes]).to be_a(Hash)
      expect(site.config['asciidoctor'][:attributes]['env']).to eql('site')
      expect(site.config['asciidoctor'][:attributes]['icons']).to eql('font')
      expect(site.config['asciidoctor'][:attributes]['sectanchors']).to eql('')
      expect(site.config['asciidoctor'][:attributes]['!table-caption']).to eql('')
    end
  end

  describe('attributes as array') do
    let(:name) do
      'attributes_as_array'
    end

    it 'should merge attributes defined as an Array into the attributes Hash' do
      expect(site.config['asciidoctor']).to be_a(Hash)
      expect(site.config['asciidoctor'][:attributes]).to be_a(Hash)
      expect(site.config['asciidoctor'][:attributes]['env']).to eql('site')
      expect(site.config['asciidoctor'][:attributes]['icons']).to eql('font')
      expect(site.config['asciidoctor'][:attributes]['sectanchors']).to eql('')
      expect(site.config['asciidoctor'][:attributes]['!table-caption']).to eql('')
    end
  end

  describe('alternate page attribute prefix') do
    let(:name) do
      'alternate_page_attribute_prefix'
    end

    before(:each) do
      site.process
    end

    it 'should strip trailing hyphen from page attribute prefix value' do
      expect(site.config['asciidoc']).to be_a(Hash)
      expect(site.config['asciidoc']['page_attribute_prefix']).to eql('jekyll')
    end

    it 'should recognize page attributes with alternate page attribute prefix' do
      page = find_page('explicit-permalink.adoc')
      expect(page).not_to be_nil
      expect(page.permalink).to eql('/permalink/')
      file = output_file('permalink/index.html')
      expect(File).to exist(file)
      contents = File.read(file)
      expect(contents).to match('<div class="page-content">')
      expect(contents).not_to match('<meta name="generator" content="Asciidoctor 1.5.4">')
    end
  end

  describe('blank page attribute prefix') do
    let(:name) do
      'blank_page_attribute_prefix'
    end

    before(:each) do
      site.process
    end

    it 'should coerce null value for page attribute prefix to empty string' do
      expect(site.config['asciidoc']).to be_a(Hash)
      expect(site.config['asciidoc']['page_attribute_prefix']).to eql('')
    end

    it 'should recognize page attributes with no page attribute prefix' do
      page = find_page('explicit-permalink.adoc')
      expect(page).not_to be_nil
      expect(page.permalink).to eql('/permalink/')
      file = output_file('permalink/index.html')
      expect(File).to exist(file)
      contents = File.read(file)
      expect(contents).to match('<div class="page-content">')
      expect(contents).not_to match('<meta name="generator" content="Asciidoctor 1.5.4">')
    end
  end

  describe('basic site') do
    let(:name) do
      'basic_site'
    end

    before(:each) do
      site.process
    end

    it 'should view a plain AsciiDoc file as having a YAML header' do
      file = source_file('without-front-matter-header.adoc')
      expect(Jekyll::Utils.has_yaml_header?(file)).to be true
    end

    it 'should convert a plain AsciiDoc file' do
      file = output_file('without-front-matter-header.html')
      expect(File).to exist(file)
      contents = File.read(file)
      expect(contents).to match('<p>Lorem ipsum.</p>')
    end

    it 'should promote AsciiDoc document title to page title' do
      file = output_file('without-front-matter-header.html')
      expect(File).to exist(file)
      contents = File.read(file)
      expect(contents).to match('<title>Page Title</title>')
    end

    it 'should view an AsciiDoc file with a front matter header as having a YAML header' do
      file = source_file('with-front-matter-header.adoc')
      expect(Jekyll::Utils.has_yaml_header?(file)).to be true
    end

    it 'should convert an AsciiDoc file with a front matter header' do
      file = output_file('with-front-matter-header.html')
      expect(File).to exist(file)
      contents = File.read(file)
      expect(contents).to match('<title>Page Title</title>')
      expect(contents).to match('<p>Lorem ipsum.</p>')
    end

    it 'should not use Liquid preprocessor by default' do
      file = output_file('no-liquid.html')
      expect(File).to exist(file)
      contents = File.read(file)
      expect(contents).to match('<p>{{ page.title }}</p>')
    end

    it 'should enable Liquid preprocessor if liquid page variable is set' do
      file = output_file('liquid-enabled.html')
      expect(File).to exist(file)
      contents = File.read(file)
      expect(contents).to match('<p>Liquid Enabled</p>')
    end

    it 'should not publish a page if the published page variable is set in the AsciiDoc header' do
      file = output_file('not-published.html')
      expect(File).not_to exist(file)
    end

    it 'should output a standalone HTML page if the page-layout attribute is unset' do
      file = output_file('standalone-a.html')
      expect(File).to exist(file)
      contents = File.read(file)
      expect(contents).to match('<meta name="generator" content="Asciidoctor 1.5.4">')
      expect(contents).to match('<title>Standalone Page A</title>')
      expect(contents).to match('<h1>Standalone Page A</h1>')
    end

    it 'should output a standalone HTML page if the page-layout attribute is false' do
      file = output_file('standalone-b.html')
      expect(File).to exist(file)
      contents = File.read(file)
      expect(contents).to match('<meta name="generator" content="Asciidoctor 1.5.4">')
      expect(contents).to match('<title>Standalone Page B</title>')
      expect(contents).to match('<h1>Standalone Page B</h1>')
    end

    it 'should apply layout named default to page content if page-layout attribute not specified' do
      file = output_file('without-front-matter-header.html')
      expect(File).to exist(file)
      contents = File.read(file)
      expect(contents).to match('<p>Footer for default layout.</p>')
    end

    it 'should apply layout named default to page content if page-layout attribute is empty' do
      file = output_file('with-empty-layout.html')
      expect(File).to exist(file)
      contents = File.read(file)
      expect(contents).to match('<p>Footer for default layout.</p>')
    end

    it 'should apply layout named default to page content if page-layout attribute has value _auto' do
      file = output_file('with-auto-layout.html')
      expect(File).to exist(file)
      contents = File.read(file)
      expect(contents).to match('<p>Footer for default layout.</p>')
    end

    it 'should apply specified layout to page content if page-layout has non-empty string value' do
      file = output_file('with-custom-layout.html')
      expect(File).to exist(file)
      contents = File.read(file)
      expect(contents).to match('<p>Footer for custom layout.</p>')
    end

    it 'should not apply a layout to page content if page-layout attribute is nil' do
      file = output_file('with-nil-layout.html')
      expect(File).to exist(file)
      contents = File.read(file)
      expect(contents).to match('div class="paragraph">
<p>Lorem ipsum.</p>
</div>')
    end

    it 'should convert an empty page attribute value to empty string' do
      page = find_page('has-page-attribute-with-empty-value.adoc')
      expect(page).not_to be_nil
      expect(page.data['attribute-with-empty-value']).to eql('')
    end
  end

  describe('site with posts') do
    let(:name) do
      'site_with_posts'
    end

    before(:each) do
      site.process
    end

    it 'should use document title as post title' do
      post = find_post('2016-01-01-welcome.adoc')
      expect(post).not_to be_nil
      expect(post.data['title']).to eql('Welcome, Visitor!')
      file = output_file('2016/01/01/welcome.html')
      expect(File).to exist(file)
      contents = File.read(file)
      expect(contents).to match('<title>Welcome, Visitor!</title>')
      expect(contents).not_to match('<h1>Welcome, Visitor!</h1>')
    end

    it 'should set author of post to value defined in AsciiDoc header' do
      post = find_post('2016-01-01-welcome.adoc')
      expect(post).not_to be_nil
      expect(post.data['author']).to eql('Henry Jekyll')
    end

    it 'should apply layout named post to post content if page-layout attribute not specified' do
      file = output_file('2016/01/01/welcome.html')
      expect(File).to exist(file)
      contents = File.read(file)
      expect(contents).to match('<p>Footer for post layout.</p>')
    end

    it 'should apply layout named post to post content if page-layout attribute is empty' do
      file = output_file('2016/01/02/with-empty-layout.html')
      expect(File).to exist(file)
      contents = File.read(file)
      expect(contents).to match('<p>Footer for post layout.</p>')
    end

    it 'should apply layout named post to post content if page-layout attribute has value _auto' do
      file = output_file('2016/01/03/with-auto-layout.html')
      expect(File).to exist(file)
      contents = File.read(file)
      expect(contents).to match('<p>Footer for post layout.</p>')
    end

    it 'should apply custom layout to post content if page-layout attribute has non-empty string value' do
      file = output_file('2016/01/04/with-custom-layout.html')
      expect(File).to exist(file)
      contents = File.read(file)
      expect(contents).to match('<p>Footer for custom layout.</p>')
    end

    it 'should not apply a layout to post content if page-layout attribute is nil' do
      file = output_file('2016/01/05/with-nil-layout.html')
      expect(File).to exist(file)
      contents = File.read(file)
      expect(contents).to match('div class="paragraph">
<p>Lorem ipsum.</p>
</div>')
    end

    it 'should show the title above the content if the showtitle attribute is set' do
      file = output_file('2016/04/01/show-me-the-title.html')
      expect(File).to exist(file)
      contents = File.read(file)
      expect(contents).to match('<title>Show Me the Title</title>')
      expect(contents).to match('<h1>Show Me the Title</h1>')
    end

    it 'should interpret value of page attribute as YAML data' do
      post = find_post('2016-02-01-post-with-categories.adoc')
      expect(post).not_to be_nil
      expect(post.data['categories']).to eql(['code', 'javascript'])
      file = output_file('code/javascript/2016/02/01/post-with-categories.html')
      expect(File).to exist(file)
    end

    it 'should apply asciidocify filter' do
      file = output_file('index.html')
      expect(File).to exist(file)
      contents = File.read(file)
      expect(contents).to match('<p class="excerpt">This is the <em>excerpt</em> of this post.</p>')
    end
  end

  describe('read error') do
    let(:name) do
      'read_error'
    end

    before(:each) do
      File.chmod(0000, source_file('unreadable.adoc'))
      site.process
    end

    after(:each) do
      File.chmod(0664, source_file('unreadable.adoc'))
    end

    it 'should not fail when file cannot be read' do
      file = output_file('unreadable.html')
      expect(File).to exist(file)
      contents = File.read(file)
      expect(contents).to be_empty
    end
  end

  describe('site with relative includes') do
    let(:name) do
      'relative_includes'
    end

    before(:each) do
      site.process
    end

    it 'should resolve includes relative to docdir when base_dir config key has value :docdir' do
      file = output_file('about/index.html')
      expect(File).to exist(file)
      contents = File.read(file)
      expect(contents).to match('Doc Writer')
      expect(contents).to match(%(docdir=#{site.config['source']}/about))
    end

    it 'should not process files that begin with an underscore' do
      file = output_file('about/_people.html')
      expect(File).not_to exist(file)
    end
  end
end
