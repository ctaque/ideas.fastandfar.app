class PostsController < ApplicationController
  SORT_OPTIONS = %w[ new top updated ].freeze
  PER_PAGE = 10
  DEFAULT_QUERY = "is:idea state:open"

  before_action :set_post, only: %i[ show edit update destroy ]
  before_action :require_author_or_admin, only: %i[ edit update ]
  before_action :require_author, only: %i[ destroy ]

  # GET /posts or /posts.json
  def index
    @sort = SORT_OPTIONS.include?(params[:sort]) ? params[:sort] : "new"
    @q = params.key?(:q) ? params[:q].to_s : DEFAULT_QUERY
    @type, @status, @author, text = parse_query(@q)

    scope = Post.all
    scope = scope.where(type: @type) if @type
    scope = scope.where(status: @status) if @status
    scope = scope.where("LOWER(user_nickname) = ?", @author.downcase) if @author
    scope = scope.where("LOWER(title) LIKE ? ESCAPE '\\'", "%#{Post.sanitize_sql_like(text.downcase)}%") if text.present?

    @total_pages = [ (scope.count.to_f / PER_PAGE).ceil, 1 ].max
    @page = params[:page].to_i.clamp(1, @total_pages)

    page_ids = sorted_post_ids(scope, @sort).offset((@page - 1) * PER_PAGE).limit(PER_PAGE).pluck(:id)
    posts_by_id = Post.includes(:votes).where(id: page_ids).index_by(&:id)
    @posts = page_ids.map { |id| posts_by_id[id] }
  end

  # GET /posts/1 or /posts/1.json
  def show
  end

  # GET /posts/new
  def new
    @post = Post.new
  end

  # GET /posts/1/edit
  def edit
  end

  # POST /posts or /posts.json
  def create
    @post = Post.new(post_params.merge(
      user_id: Current.user.id,
      user_email: Current.user.email_address,
      user_nickname: Current.user.nickname,
      user_avatar_url: Current.user.avatar_url
    ))

    respond_to do |format|
      if @post.save
        MentionNotifier.notify(@post.content, post_id: @post.id, access_token: cookies[:access_token])
        NewPostNotificationJob.perform_later(
          post_id: @post.id,
          title: @post.title,
          excerpt: @post.content.to_plain_text.truncate(280),
          access_token: cookies[:access_token]
        )
        format.html { redirect_to @post, notice: "Post was successfully created." }
        format.json { render :show, status: :created, location: @post }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @post.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /posts/1 or /posts/1.json
  def update
    respond_to do |format|
      if @post.update(post_params)
        format.html { redirect_to @post, notice: "Post was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @post }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @post.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /posts/1 or /posts/1.json
  def destroy
    @post.destroy!

    respond_to do |format|
      format.html { redirect_to posts_path, notice: "Post was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_post
      @post = Post.find(params.expect(:id))
    end

    def require_author
      head :forbidden unless @post.user_id == Current.user.id
    end

    def require_author_or_admin
      head :forbidden unless @post.user_id == Current.user.id || Current.user.admin?
    end

    # Parses a GitHub-issues-style query string such as "is:idea state:open
    # author:bob foo" into a [type, status, author, remaining_text] tuple.
    # Unknown is:/state: values are ignored; author accepts any nickname as-is,
    # since Rails doesn't own the users table (fastandfarapp does) and just
    # matches whatever it already has cached on the post. Everything else is
    # treated as a title search term.
    def parse_query(query)
      type = nil
      status = nil
      author = nil
      text_terms = []

      query.split(/\s+/).each do |token|
        case token
        when /\Ais:(.+)\z/i
          candidate = $1.downcase
          type = candidate if Post.types.key?(candidate)
        when /\Astate:(.+)\z/i
          candidate = $1.downcase.tr("-", "_")
          status = candidate if Post.statuses.key?(candidate)
        when /\Aauthor:(.+)\z/i
          author = $1
        else
          text_terms << token
        end
      end

      [ type, status, author, text_terms.join(" ") ]
    end

    def sorted_post_ids(scope, sort)
      case sort
      when "top"
        scope.left_joins(:votes).group(:id).order(Arel.sql("COALESCE(SUM(votes.value), 0) DESC, posts.id DESC"))
      when "updated"
        scope.order(updated_at: :desc)
      else
        scope.order(created_at: :desc)
      end
    end

    # Only allow a list of trusted parameters through.
    def post_params
      params.expect(post: [ :title, :content, :type ])
    end
end
