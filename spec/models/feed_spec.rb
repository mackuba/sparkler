require 'rails_helper'

describe Feed do
  fixtures :feeds

  let(:feed) { Feed.first }
  let(:last_version) { '2.0' }
  let(:xml) { %(
    <rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
      <item>
        <enclosure url="blblblb" sparkle:version="#{last_version}" />
      </item>
      <item>
        <enclosure url="blblblb" sparkle:version="0.1" />
      </item>
    </rss>
  )}

  describe '#load_contents' do
    it 'should load feed contents' do
      stub_request(:get, feed.url).to_return(body: xml)

      feed.load_contents

      feed.contents.should == xml
    end

    it 'should reset the error property' do
      feed.load_error = StandardError.new

      stub_request(:get, feed.url).to_return(body: xml)

      feed.load_contents

      feed.load_error.should be_nil
    end

    context 'if the location is a local path' do
      before { feed.update_attributes(url: File.expand_path(__FILE__)) }

      it 'should load the file from there' do
        expect { feed.load_contents }.not_to raise_error

        feed.load_error.should be_nil
        feed.contents.should == File.read(__FILE__)
      end
    end

    context 'if the location redirects from HTTP to HTTPS' do
      it 'should follow the redirect' do
        https_url = feed.url.gsub(/http:/, 'https:')
        stub_request(:get, feed.url).to_return(:status => 301, :headers => { 'Location' => https_url })
        stub_request(:get, https_url).to_return(body: xml)

        expect { feed.load_contents }.not_to raise_error

        feed.load_error.should be_nil
        feed.contents.should == xml
      end
    end

    it 'should parse last version number from the feed' do
      stub_request(:get, feed.url).to_return(body: xml)

      feed.load_contents

      feed.last_version.should == last_version
    end

    context 'if items include both version and build number' do
      let(:xml) { %(
        <rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
          <item>
            <enclosure url="blblblb" sparkle:version="111" sparkle:shortVersionString="#{last_version}" />
          </item>
          <item>
            <enclosure url="blblblb" sparkle:version="222" sparkle:shortVersionString="0.1" />
          </item>
        </rss>
      )}

      it 'should take the short version string' do
        stub_request(:get, feed.url).to_return(body: xml)

        feed.load_contents

        feed.last_version.should == last_version
      end
    end

    context 'if items include version string in a <sparkle:version> tag' do
      let(:xml) { %(
        <rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
          <item>
            <sparkle:version>#{last_version}</sparkle:version>
          </item>
          <item>
            <sparkle:version>0.1</sparkle:version>
          </item>
        </rss>
      )}

      it 'should parse the version correctly' do
        stub_request(:get, feed.url).to_return(body: xml)

        feed.load_contents

        feed.last_version.should == last_version
      end
    end

    context "if the feed doesn't contain any items" do
      let(:xml) { "" }

      it 'should not raise any errors' do
        stub_request(:get, feed.url).to_return(body: xml)

        expect { feed.load_contents }.not_to raise_error

        feed.contents.should == ""
      end

      it 'should not set the error property' do
        stub_request(:get, feed.url).to_return(body: xml)

        feed.load_contents

        feed.load_error.should be_nil
      end

      it 'should set last_version to nil' do
        stub_request(:get, feed.url).to_return(body: xml)

        feed.load_contents

        feed.last_version.should be_nil
      end
    end

    context "if feed can't be loaded" do
      it 'should not raise an exception' do
        stub_request(:get, feed.url).to_raise(SocketError)

        expect { feed.load_contents }.not_to raise_error
      end

      it 'should set the error property' do
        stub_request(:get, feed.url).to_raise(SocketError)

        feed.load_contents

        feed.load_error.should_not be_nil
      end

      context 'if data was previously loaded' do
        before { feed.contents = 'ffffff' }

        it 'should not reset it' do
          stub_request(:get, feed.url).to_raise(SocketError)

          feed.load_contents
          
          feed.contents.should_not be_nil
        end
      end
    end

    context "if the feed doesn't include sparkle namespace" do
      let(:xml) { %(
        <rss>
          <item>
            <sparkle:version>#{last_version}</sparkle:version>
          </item>
          <item>
            <sparkle:version>0.1</sparkle:version>
          </item>
        </rss>
      )}

      it 'should not raise an exception' do
        stub_request(:get, feed.url).to_return(body: xml)

        expect { feed.load_contents }.not_to raise_error
      end

      it 'should set the error property' do
        stub_request(:get, feed.url).to_return(body: xml)

        feed.load_contents

        feed.load_error.should_not be_nil
      end
    end
  end

  describe '#load_if_needed' do
    context 'if feed is not loaded yet' do
      it 'should load it' do
        data = stub_request(:get, feed.url)
        
        feed.load_if_needed
        
        data.should have_been_requested
      end
    end

    context 'if feed is already loaded' do
      before { feed.contents = 'xxxxx' }

      it 'should not load it' do
        data = stub_request(:get, feed.url)
        
        feed.load_if_needed
        
        data.should_not have_been_requested
      end
    end
  end

  context 'when feed is edited' do
    before do
      feed.contents = 'xxxxxxx'
      feed.last_version = '1.0'
      feed.load_error = Exception.new
      feed.save!
    end

    context 'if url is changed' do
      it 'should reset cached data' do
        feed.update_attributes(url: 'http://gazeta.pl')

        feed.contents.should be_nil
        feed.last_version.should be_nil
        feed.load_error.should be_nil
      end
    end

    context 'if url is not changed' do
      it 'should not reset cached data' do
        feed.update_attributes(name: 'blblbllb')

        feed.contents.should_not be_nil
        feed.last_version.should_not be_nil
        feed.load_error.should_not be_nil
      end
    end
  end
end
