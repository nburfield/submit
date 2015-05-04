class CommentsController < ApplicationController
  # Creates a new comment
  def create
    @upload_datum = UploadDatum.find(params[:upload_id])
    @new_comment = @upload_datum.comments.new(comment_params)
    @file_comments = @upload_datum.comments
    @all_comments = @upload_datum.submission.assignment.get_all_comments.sort_by { |_key, value| value }.reverse

    if @new_comment.save
      @file_comments = @upload_datum.comments
      @all_comments = @upload_datum.submission.assignment.get_all_comments
      if @all_comments[@new_comment.contents] == nil
        @all_comments[@new_comment.contents] = 1
      else
        @all_comments[@new_comment.contents] += 1
      end
      @all_comments.sort_by { |_key, value| value }.reverse

      respond_to do |format|
        format.js { render :action => "refresh" }
      end
    else
      respond_to do |format|
        format.js { render :action => "error" }
      end
    end
  end

  def destroy
    @new_comment = Comment.find(params[:id])
    @new_comment.destroy
    @file_comments = @new_comment.upload_datum.comments
    @all_comments = @new_comment.upload_datum.submission.assignment.get_all_comments.sort_by { |_key, value| value }.reverse

    respond_to do |format|
      format.js { render :action => "refresh" }
    end
  end

  private
  def comment_params
    params.require(:comment).permit(:contents, :line)
  end
end
