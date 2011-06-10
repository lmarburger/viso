require 'spec_helper'
require 'rack/test'
require 'support/vcr'

require 'viso'

describe Viso do

  include Rack::Test::Methods

  def app
    Viso.tap { |app| app.set :environment, :test }
  end

  it 'redirects the home page to the CloudApp product page' do
    EM.synchrony do
      VCR.use_cassette 'default_domain_details',
                       :erb => { :domain => 'cl.ly' } do
        get '/'
        EM.stop

        assert { last_response.redirect? }

        headers = last_response.headers
        assert { headers['Cache-Control'] == 'public, max-age=3600' }
        assert { headers['Vary']          == 'Accept' }
        assert { headers['Location']      == 'http://getcloudapp.com' }
      end
    end
  end

  it "redirects the home page of a custom domain to it's home page" do
    EM.synchrony do
      VCR.use_cassette 'domain_details', :erb => { :domain => 'example.org' } do
        get '/'
        EM.stop

        assert { last_response.redirect? }

        headers = last_response.headers
        assert { headers['Cache-Control'] == 'public, max-age=3600' }
        assert { headers['Vary']          == 'Accept' }
        assert { headers['Location']      == 'http://hhgproject.org' }
      end
    end
  end

  it 'returns a not found response for nonexistent drops' do
    EM.synchrony do
      VCR.use_cassette 'nonexistent' do
        get '/hhgttg'
        EM.stop

        assert { last_response.not_found? }
        assert { last_response.body == '<h1>Not Found</h1>' }
      end
    end
  end

  it 'redirects the content URL to the API' do
    EM.synchrony do
      get '/hhgttg/chapter1.txt'
      EM.stop

      assert { last_response.redirect? }

      headers = last_response.headers
      assert { headers['Cache-Control'] == 'public, max-age=900' }
      assert { headers['Vary']          == 'Accept' }
      assert { headers['Location']      == 'http://api.cld.me/hhgttg/chapter1.txt' }
    end
  end

  it 'redirects a bookmark to the API' do
    EM.synchrony do
      VCR.use_cassette 'bookmark' do
        get '/hhgttg'
        EM.stop

        assert { last_response.redirect? }

        headers = last_response.headers
        assert { headers['Cache-Control'] == 'public, max-age=900' }
        assert { headers['Vary']          == 'Accept' }
        assert { headers['Location']      == 'http://api.cld.me/hhgttg' }
      end
    end
  end

  it "redirects a bookmark's content URL to the API" do
    EM.synchrony do
      VCR.use_cassette 'bookmark' do
        get '/hhgttg/content'
        EM.stop

        assert { last_response.redirect? }

        headers = last_response.headers
        assert { headers['Cache-Control'] == 'public, max-age=900' }
        assert { headers['Vary']          == 'Accept' }
        assert { headers['Location']      == 'http://api.cld.me/hhgttg/content' }
      end
    end
  end

  it 'displays an image drop' do
    EM.synchrony do
      VCR.use_cassette 'image' do
        get '/hhgttg'
        EM.stop

        assert { last_response.ok? }

        headers = last_response.headers
        assert { headers['Cache-Control'] == 'public, max-age=900' }
        assert { headers['Vary']          == 'Accept' }

        image_tag = %{<img alt="cover.png" src="http://cl.ly/hhgttg/cover.png">}
        assert { last_response.body.include?(image_tag) }
      end
    end
  end

  it 'displays an original image drop' do
    EM.synchrony do
      VCR.use_cassette 'image' do
        get '/hhgttg/o'
        EM.stop

        assert { last_response.ok? }

        headers = last_response.headers
        assert { headers['Cache-Control'] == 'public, max-age=900' }
        assert { headers['Vary']          == 'Accept' }

        image_tag = %{<img alt="cover.png" src="http://cl.ly/hhgttg/cover.png">}
        assert { last_response.body.include?(image_tag) }
      end
    end
  end

  it 'shows a download button for an unknown file' do
    EM.synchrony do
      VCR.use_cassette 'unknown' do
        get '/hhgttg'
        EM.stop

        assert { last_response.ok? }

        headers = last_response.headers
        assert { headers['Cache-Control'] == 'public, max-age=900' }
        assert { headers['Vary']          == 'Accept' }

        assert { last_response.body.include?('<body id="other">') }
        deny   { last_response.body.include?("<img") }

        title = %{<title>Chapter 1</title>}
        assert { last_response.body.include?(title) }

        heading = %{<h1 class="description left unknown">Chapter 1</h1>}
        assert { last_response.body.include?(heading) }

        link = %{<a href="http://cl.ly/hhgttg/Chapter_1.blah">Download</a>}
        assert { last_response.body.include?(link) }
      end
    end
  end

  it 'shows a download button for a text file' do
    EM.synchrony do
      VCR.use_cassette 'text' do
        get '/hhgttg'
        EM.stop

        assert { last_response.ok? }

        headers = last_response.headers
        assert { headers['Cache-Control'] == 'public, max-age=900' }
        assert { headers['Vary']          == 'Accept' }

        assert { last_response.body.include?('<body id="other">') }
        deny   { last_response.body.include?("<img") }

        title = %{<title>chapter1.txt</title>}
        assert { last_response.body.include?(title) }

        heading = %{<h1 class="description left text">chapter1.txt</h1>}
        assert { last_response.body.include?(heading) }

        link = %{<a href="http://cl.ly/hhgttg/chapter1.txt">Download</a>}
        assert { last_response.body.include?(link) }
      end
    end
  end

  ## This test will fail until webmock can support the latest em-http-request
  #it 'dumps the content of an html drop' do
    #EM.synchrony do
      #VCR.use_cassette 'html' do
        #get '/hhgttg'
        #EM.stop

        #assert { last_response.ok? }

        #headers = last_response.headers
        #assert { headers['Cache-Control'] == 'public, max-age=900' }
        #assert { headers['Vary']          == 'Accept' }
        #assert { headers['Content-Type']  == 'text/html;charset=utf-8' }

        #heading_tag = '<h1>Chapter 1</h1>'
        #assert { last_response.body.include? heading_tag }
      #end
    #end
  #end

  ## This test will fail until webmock can support the latest em-http-request
  #it 'dumps the content of a markdown drop' do
    #EM.synchrony do
      #VCR.use_cassette 'markdown' do
        #get '/hhgttg'
        #EM.stop

        #assert { last_response.ok? }

        #headers = last_response.headers
        #assert { headers['Cache-Control'] == 'public, max-age=900' }
        #assert { headers['Vary']          == 'Accept' }
        #assert { headers['Content-Type']  == 'text/html;charset=utf-8' }

        #section_tag = '<section class="monsoon" id="content">'
        #assert { last_response.body.include? section_tag }

        #content = 'The house stood on a slight rise just on the edge of the village.'
        #assert { last_response.body.include? content }
      #end
    #end
  #end

  ## This test will fail until webmock can support the latest em-http-request
  #it 'dumps the content of a code drop' do
    #EM.synchrony do
      #VCR.use_cassette 'ruby-test', :record => :new_episodes do
        #get '/1k0f342Q1R373x2h3q2I'
        #EM.stop

        #assert { last_response.ok? }

        #headers = last_response.headers
        #assert { headers['Cache-Control'] == 'public, max-age=900' }
        #assert { headers['Vary']          == 'Accept' }
        #assert { headers['Content-Type']  == 'text/html;charset=utf-8' }

        #section_tag = '<section class="monsoon" id="content">'
        #assert { last_response.body.include? section_tag }

        #content = 'The house stood on a slight rise just on the edge of the village.'
        #assert { last_response.body.include? content }
      #end
    #end
  #end

  it 'forwards json response' do
    EM.synchrony do
      VCR.use_cassette 'text' do
        header 'Accept', 'application/json'
        get    '/hhgttg'
        drop = Drop.find 'hhgttg'
        EM.stop

        assert { last_response.ok? }

        headers = last_response.headers
        assert { headers['Cache-Control'] == 'public, max-age=900' }
        assert { headers['Vary']          == 'Accept' }
        assert { headers['Content-Type']  == 'application/json' }

        assert { last_response.body == Yajl::Encoder.encode(drop.data) }
      end
    end
  end

  it 'respects accept header priority' do
    EM.synchrony do
      VCR.use_cassette 'text' do
        header 'Accept', 'text/html,application/json'
        get    '/hhgttg'
        EM.stop

        assert do
          last_response.headers['Content-Type'] == 'text/html;charset=utf-8'
        end
      end
    end
  end

  it 'serves html by default' do
    EM.synchrony do
      VCR.use_cassette 'text' do
        header 'Accept', '*/*'
        get    '/hhgttg'
        EM.stop

        assert do
          last_response.headers['Content-Type'] == 'text/html;charset=utf-8'
        end
      end
    end
  end

end
