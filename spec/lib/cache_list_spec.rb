require 'spec_helper'

describe Kaching::CacheList do
  let(:user) { User.create }

  context "non-polymorphic" do
    it "should add/remove/has" do
      movie1 = Movie.create!
      movie2 = Movie.create!
    
      user.has_user_movie?(movie1).should be_false
      user.add_user_movie!(movie1)
        
      user.has_user_movie?(movie1).should be_true
        
      user.add_user_movie!(movie2)
      user.has_user_movie?(movie2).should be_true
  
      user.remove_user_movie!(movie1)
      user.has_user_movie?(movie1).should be_false
      user.has_user_movie?(movie2).should be_true
      
      id = user.id
        
      user = User.find(id)
      user.has_user_movie?(movie1).should be_false
      user.has_user_movie?(movie2).should be_true
    end
  end
  
  context "polymorphic" do
    it "should create method on user" do
      user.should respond_to(:like!)
      user.should respond_to(:unlike!)
      user.should respond_to(:likes?)
      user.should respond_to(:likes)
      user.should respond_to(:likes_count)
    end
  
    it "should add/remove/has" do
      Movie.create!
      
      movie1 = Movie.create!
      movie2 = Movie.create!
    
      user.likes_count.should == 0
      user.likes?(movie1).should be_false
      user.like!(movie1)
      user.like!(movie2)
      user.likes_count.should == 2
      user.likes?(movie1).should be_true
      user.likes?(movie2).should be_true
      user.unlike!(movie1)
      user.likes_count.should == 1
      user.likes?(movie1).should be_false
    
      id = user.id
    
      user = User.find(id)
      user.likes?(movie1).should be_false
      user.likes?(movie2).should be_true
    end
  
    it "should support creation/has w/o built-in methods" do
      movie1 = Movie.create!
      movie2 = Movie.create!
    
      Like.connection.execute "INSERT INTO likes (user_id, item_id, item_type) VALUES (#{user.id}, #{movie1.id}, 'Movie')"
      Like.create!(user: user, item: movie2)
    
      user.likes?(movie1).should be_true
      user.likes?(movie2).should be_true
    end
  
    it "should toggle" do
      movie1 = Movie.create!
  
      user.likes?(movie1).should be_false
      user.toggle_like!(movie1)
      user.likes?(movie1).should be_true
      
      user.toggle_like!(movie1)
      user.likes?(movie1).should be_false
      
      user.like!(movie1)
      user.likes?(movie1).should be_true
      
      user.toggle_like!(movie1, false)
      user.likes?(movie1).should be_false
      
      user.toggle_like!(movie1, true)
      user.likes?(movie1).should be_true
    end
      
    it "should support creation/has w/o built-in methods, by resetting cache after manual insertion" do
      movie1 = Movie.create!
    
      # this creates the cache
      user.likes?(movie1).should be_false
    
      # this doesn't update cache
      Like.connection.execute "INSERT INTO likes (user_id, item_id, item_type) VALUES (#{user.id}, #{movie1.id}, 'Movie')"
    
      user.reset_list_cache_likes!
      user.likes?(movie1).should be_true
    end
  end

  context "two relationships on same model" do
    it "should manage counts" do
      follower_user = User.create!
      followed_user = User.create!
      
      follower_user.should respond_to(:follower_users_count)
      follower_user.should respond_to(:following_users_count)
      
      follower_user.follower_users_count.should == 0
      followed_user.following_users_count.should == 0
      
      expect { expect { expect { expect {
        follower_user.follow! followed_user
      }.to change(followed_user, :follower_users_count).by(1)
      }.to change(follower_user, :following_users_count).by(1)
      }.to_not change(follower_user, :follower_users_count)
      }.to_not change(followed_user, :following_users_count)
      
      expect { expect { expect { expect {
        follower_user.unfollow! followed_user
      }.to change(followed_user, :follower_users_count).by(-1)
      }.to change(follower_user, :following_users_count).by(-1)
      }.to_not change(follower_user, :follower_users_count)
      }.to_not change(followed_user, :following_users_count)
    end
  end
end
