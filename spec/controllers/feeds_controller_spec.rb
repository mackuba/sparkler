require 'rails_helper'

describe FeedsController do
  fixtures :feeds

  before { session[:logged_in] = true }

  let(:feed) { feeds(:feed1) }
  let(:new_url) { 'http://foo.bar' }

  def self.it_should_require_admin(&block)
    context 'if user is not logged in' do
      before { session.delete(:logged_in) }

      it 'should redirect to the login page' do
        instance_eval(&block)

        response.should redirect_to('/user/login_form')
      end
    end
  end

  describe '#show' do
    before do
      session.delete(:logged_in)
      stub_request(:get, feed.url)
    end

    context 'if feed is loaded' do
      before { feed.update_attributes(contents: 'txt') }

      it 'should return feed body' do
        get :show, params: { id: feed.name }

        response.should be_success
        response.body.should == 'txt'
      end

      it 'should not reload the feed' do
        get :show, params: { id: feed.name }

        WebMock.should_not have_requested(:get, feed.url)
      end
    end

    context 'if feed is not loaded' do
      before { feed.update_attributes(contents: nil) }

      it 'should reload the feed' do
        get :show, params: { id: feed.name }

        WebMock.should have_requested(:get, feed.url)
      end

      context 'if feed loading succeeds' do
        before { stub_request(:get, feed.url).to_return(body: 'foo') }

        it 'should return feed body' do
          get :show, params: { id: feed.name }

          response.should be_success
          response.body.should == 'foo'
        end
      end

      context 'if feed loading fails' do
        before { stub_request(:get, feed.url).to_return(status: 400) }

        it 'should return 404' do
          get :show, params: { id: feed.name }

          response.code.should == '404'
        end
      end
    end

    context 'if the request is made from the app using Sparkle' do
      before { @request.user_agent = 'MyApp/1.5 Sparkle/313' }

      it 'should save statistics based on GET parameters and user agent' do
        get :show, params: { id: feed.name, cpuType: '44' }

        feed.statistics.detect { |s|
          s.date == Date.today && s.property.name == 'cpuType' && s.option.name == '44'
        }.should_not be_nil

        feed.statistics.detect { |s|
          s.date == Date.today && s.property.name == 'appVersionShort' && s.option.name == '1.5'
        }.should_not be_nil
      end
    end

    context 'if the request is made from another app' do
      before { @request.user_agent = 'AppFresh/1.0.5 (909) (Mac OS X)' }

      it 'should not save any statistics' do
        get :show, params: { id: feed.name, cpuType: '44' }

        feed.statistics.detect { |s| s.date == Date.today }.should be_nil
      end
    end

    context 'if feed is inactive' do
      let(:feed) { feeds(:inactive) }

      it 'should return ActiveRecord::RecordNotFound' do
        expect { get :show, params: { id: feed.name }}.to raise_error(ActiveRecord::RecordNotFound)

        WebMock.should_not have_requested(:get, feed.url)
      end
    end
  end

  describe '#index' do
    it 'should load feeds' do
      get :index

      response.should be_success
      response.should render_template(:index)

      feeds = assigns(:feeds)
      feeds.should_not be_nil
      feeds.should_not be_empty
    end

    it 'should show all inactive feeds at the end' do
      get :index

      had_inactive = false

      assigns(:feeds).each do |feed|
        if feed.inactive?
          had_inactive = true
        end

        if had_inactive
          feed.should be_inactive
        end
      end
    end

    it_should_require_admin { get :index }
  end

  describe '#reload' do
    before do
      stub_request(:get, feed.url)
      feed.update_attributes(contents: 'txt')
    end

    it 'should reload the feed' do
      post :reload, params: { id: feed.name }

      WebMock.should have_requested(:get, feed.url)
    end

    it 'should redirect to the index page' do
      post :reload, params: { id: feed.name }

      response.should redirect_to(feeds_path)
    end

    context 'if request was made with XHR' do
      it 'should return a rendered feed partial instead' do
        post :reload, params: { id: feed.name}, xhr: true

        response.should be_success
        response.should render_template('_feed')
      end
    end

    it_should_require_admin { post :reload, params: { id: feed.name }}
  end

  describe '#new' do
    it 'should load a new feed form' do
      get :new

      response.should be_success
      response.should render_template(:new)
    end

    it_should_require_admin { get :new }
  end

  describe '#create' do
    let(:params) {{ name: 'foo', title: 'Foo', url: new_url }}

    context 'if feed is valid' do
      before do
        stub_request(:get, new_url)
      end

      it 'should save the feed' do
        post :create, params: { feed: params }

        Feed.find_by_name(params[:name]).should_not be_nil
      end

      it 'should redirect to the index page' do
        post :create, params: { feed: params }

        response.should redirect_to(feeds_path)
      end

      it 'should load the feed' do
        post :create, params: { feed: params }

        WebMock.should have_requested(:get, new_url)
      end
    end

    context 'if feed is invalid' do
      it 'should render the new feed form again' do
        post :create, params: { feed: params.merge(title: '') }

        response.should render_template(:new)
      end
    end

    it_should_require_admin { post :create, params: { feed: params }}
  end

  describe '#edit' do
    it 'should load an edit form' do
      get :edit, params: { id: feed.name }

      response.should be_success
      response.should render_template(:edit)
    end

    it_should_require_admin { get :edit, params: { id: feed.name }}
  end

  describe '#update' do
    context 'if feed is valid' do
      before do
        stub_request(:get, feed.url)
        feed.update_attributes(contents: 'txt')
      end

      it 'should save the feed' do
        patch :update, params: { id: feed.name, feed: { name: 'foo' }}

        feed.reload

        feed.name.should == 'foo'
      end

      it 'should redirect to the index page' do
        patch :update, params: { id: feed.name, feed: { name: 'foo' }}

        response.should redirect_to(feeds_path)
      end

      context 'if url was changed' do
        it 'should reload the feed' do
          stub_request(:get, new_url)
          old_url = feed.url

          patch :update, params: { id: feed.name, feed: { url: new_url }}

          WebMock.should_not have_requested(:get, old_url)
          WebMock.should have_requested(:get, new_url)
        end
      end

      context 'if url was not changed' do
        it 'should not reload the feed' do
          patch :update, params: { id: feed.name, feed: { name: 'foo' }}

          WebMock.should_not have_requested(:get, feed.url)
        end
      end
    end

    context 'if feed is invalid' do
      it 'should render the edit form again' do
        patch :update, params: { id: feed.name, feed: { name: '' }}

        response.should render_template(:edit)
      end
    end

    it_should_require_admin { patch :update, params: { id: feed.name, feed: { name: 'foo' }}}
  end
end
