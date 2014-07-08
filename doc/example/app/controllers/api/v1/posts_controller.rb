class API::V1::PostsController < APIController
  handles :all

  def show
    super

    @post.update_attributes(view_count: @post.view_count+1)
  end

  private
    def post_params
      params.require(:post).permit(:title, :body, :published, :author_id,
                                   author_attributes: [:name],
                                   comments_attributes: [:id, :content])
    end
end
