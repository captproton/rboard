class PostsController < ApplicationController
  before_filter :login_required
  before_filter :find_topic
  before_filter :find_user, :only => [:index]
  before_filter :find_post, :only => [:edit, :update, :destroy]
  before_filter :create_ip, :only => [:create, :update]
  
  def index
    @posts = @user.posts.paginate :per_page => per_page, :page => params[:page]
    
  end
  
  def new
    @posts = @topic.last_10_posts
    @post ||= @topic.posts.build(:user => current_user)
  end

  def create
    @topic = Topic.find(params[:topic_id], :include => :posts)
    
    # The last 10 posts for this topic
    @posts = @topic.posts.find(:all, :order => "id DESC", :limit => 10)
    
    @post = @topic.posts.build(params[:post].merge!(:user => current_user, :ip => @ip))
    
    if @post.save
      flash[:notice] = t(:created, :thing => "post")
      go_directly_to_post
    else
      @quoting_post = Post.find(params[:quote]) unless params[:quote].blank?
      flash.now[:notice] = t(:not_created, :thing => "post")
      render :action => "new"
    end
  end
   
  def edit
  end
  
  def update
    @topic = @post.topic
    if @post.update_attributes(params[:post])
      if @post.text_changed?
        @post.edits.create(:original_content => @post.text,
                           :current_content => params[:post][:text],
                           :user => current_user, 
                           :ip => request.remote_ip,
                           :hidden => params[:silent_edit] == "1",
                           :ip => @ip)
        @post.update_attribute("edited_by", current_user)
      end
      flash[:notice] = t(:updated, :thing => "post")
      go_directly_to_post
    else
      flash.now[:notice] = t(:not_updated, :thing => "post")
      render :action => "edit"
    end
  end
  
  def destroy
    @post.destroy
    flash[:notice] = t(:deleted, :thing => "post")
    if @post.topic.posts.size.zero?
      @post.topic.destroy
      flash[:notice] += t(:topic_too)
      redirect_to forum_path(@post.forum)
    else
      redirect_to forum_topic_path(@post.forum, @post.topic)
    end
  end
  
  # Not using the find_post method here because we're storing it as quoting_post.
  def reply
    if current_user.can?(:reply)
      quoting_post = Post.find(params[:id])
      @post = @topic.posts.build(:user => current_user)
      @post.text = "[quote=\"#{quoting_post.user}\"]#{quoting_post.text}[/quote]"
      render :action => "new"
    else
      flash[:notice] = t(:can_not_reply)
      redirect_to forum_topic_path(@topic.forum, @topic)
    end
      
  end
  
  private
  
    def not_found
      flash[:notice] = t(:not_found, :thing => "post")
      redirect_back_or_default(forums_path)
    end
    
    def find_topic
      @topic = Topic.find(params[:topic_id], :include => :posts) unless params[:topic_id].nil?
    end
    
    def find_post
      @post = Post.find(params[:id])
      check_ownership
    rescue ActiveRecord::RecordNotFound
      not_found
    end
    
    def find_user
      @user = User.find(params[:user_id])
    end
    
    def create_ip
      @ip = Ip.find_or_create_by_ip(request.remote_ip)
      IpUser.create(:ip => @ip, :user => current_user)
    end
    
    def check_ownership
      if (@post.belongs_to?(current_user) && !current_user.can?(:edit_own_posts, @post.forum)) ||
         (!@post.belongs_to?(current_user) && !current_user.can?(:edit_posts, @post.forum))
        flash[:notice] = t(:Cannot_edit_post)
        redirect_back_or_default(forums_path)
      end
    end
    
    def go_directly_to_post
      redirect_to forum_topic_path(@post.forum,@topic) + "/#{@post.page_for(current_user)}" + "#post_#{@post.id}"
    end
end