require 'rails_helper'

describe StatisticsController do
  fixtures :feeds

  describe '#index' do
    before { session[:logged_in] = true }

    context 'if feed is inactive' do
      let(:feed) { feeds(:inactive) }

      it 'should return ActiveRecord::RecordNotFound' do
        expect { get :index, params: { feed_id: feed.name }}.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'if feed is private' do
      let(:feed) { feeds(:private) }

      context 'if user is logged in' do
        it 'should render the page' do
          get :index, params: { feed_id: feed.name }

          response.should be_success
        end

        it 'should include counts' do
          get :index, params: { feed_id: feed.name }

          assigns(:include_counts).should == true
        end
      end

      context 'if user is not logged in' do
        before { session.delete(:logged_in) }

        it 'should redirect to login page' do
          get :index, params: { feed_id: feed.name }

          response.should redirect_to('/user/login_form')
        end
      end
    end

    context 'if feed is public' do
      let(:feed) { feeds(:public) }

      context 'if user is not logged in' do
        before { session.delete(:logged_in) }

        it 'should render the page' do
          get :index, params: { feed_id: feed.name }

          response.should be_success
        end

        it 'should include counts' do
          get :index, params: { feed_id: feed.name }

          assigns(:include_counts).should == true
        end
      end
    end

    context 'if feed is public without counts' do
      let(:feed) { feeds(:public_no_counts) }

      context 'if user is logged in' do
        it 'should render the page' do
          get :index, params: { feed_id: feed.name }

          response.should be_success
        end

        it 'should include counts' do
          get :index, params: { feed_id: feed.name }

          assigns(:include_counts).should == true
        end
      end

      context 'if user is not logged in' do
        before { session.delete(:logged_in) }

        it 'should render the page' do
          get :index, params: { feed_id: feed.name }

          response.should be_success
        end

        it 'should NOT include counts' do
          get :index, params: { feed_id: feed.name }

          assigns(:include_counts).should be_falsy
        end
      end
    end
  end
end