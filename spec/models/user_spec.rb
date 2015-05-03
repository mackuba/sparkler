require 'rails_helper'

describe User do
  describe '.find_admin' do
    context 'if a user exists' do
      let!(:user) { User.create!(password: 'aaaaaa', password_confirmation: 'aaaaaa') }

      it 'should return that user' do
        User.find_admin.should == user
      end
      
      it 'should not create new users' do
        expect { User.find_admin }.not_to change(User, :count)
      end
    end

    context 'if no users exist' do
      it 'should return a new user' do
        User.find_admin.should be_a(User)
      end
      
      it 'should create one user' do
        User.find_admin
        User.count.should == 1
      end

      context 'new user' do
        it 'should not have a password' do
          user = User.find_admin
          user.password_digest.should be_nil
        end
      end
    end
  end

  describe '#has_password?' do
    subject { user.has_password? }

    context 'if the user has a password' do
      let!(:user) { User.create(password: 'password', password_confirmation: 'password') }

      it { should == true }
    end

    context 'if the user has no password' do
      let!(:user) { User.find_admin }

      it { should == false }
    end
  end
end
