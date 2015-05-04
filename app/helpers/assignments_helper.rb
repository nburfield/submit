module AssignmentsHelper
  def require_admin
    if not current_user.has_role? :admin
      flash[:notice] = "Only admins may view this page"
      redirect_to dashboard_url
    end
  end

  def require_instructor
    return if current_user.has_role? :admin
    
    if not current_user.has_role? :instructor
      flash[:notice] = "Only instructors may view this page"
      redirect_to dashboard_url
    end
  end

  def require_enrolled
    assignment = Assignment.find(params[:id])
    course = assignment.course
    if not course.users.include? current_user and not current_user.has_role? :admin
      flash[:notice] = "You may only view assignmets if you are enrolled in the course"
      redirect_to dashboard_url
    end
  end

  def require_instructor_owner
    return if current_user.has_role? :admin

    if params.has_key? :course_id
      course = Course.find(params[:course_id])
    else
      assignment = Assignment.find(params[:id])
      course = assignment.course
    end
    
    if not current_user.has_role? :instructor, course
      flash[:notice] = "You must be an instructor of the course to view that page"
      redirect_to dashboard_url
    end
  end
end
