class TasksController < ApplicationController
  unloadable
  before_filter :find_project, :except => [:destroy]
  # GET /tasks
  # GET /tasks.xml
  def index
    @tasks = Task.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @tasks }
    end
  end

  # GET /tasks/1
  # GET /tasks/1.xml
  def show
    @task = Task.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @task }
    end
  end

  # GET /tasks/new
  # GET /tasks/new.xml
  def new
    @task = Task.new
    session[:selected_user_story] = params[:user_story_id]
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @task }
    end
  end

  # GET /tasks/1/edit
  def edit
    @task = Task.find(params[:id])
  end

  # POST /tasks
  # POST /tasks.xml
  def create
    @task = Task.new(params[:task])
    @task.user_story_id = params[:userstory_id]
    @task.author  = User.current
    
    devs = []
    @task.users = []
    for developer in params[:task][:user_ids] do
      if developer != ""
        devs += [User.find(developer)]
      end
    end
    @task.users << devs
    
    if @task.save
      log_task(@task)
      redirect_to url_for_object(@task.user_story.sprint,@project,"show")
    else
      respond_to do |format|
        format.html { render :action => "new" }
        format.xml  { render :xml => @task.errors, :status => :unprocessable_entity }
      end
    end
  end

  def status_change
    task = Task.find(params[:id])
    unless task.nil?
#      if (task.status_id.to_s != params[:status_id].to_s || (!params[:user_story_id].nil? && params[:user_story_id].to_s != task.user_story_id.to_s ))
        task.status_id = params[:status_id]
        task.author = User.current
        if !params[:user_story_id].nil? and params[:user_story_id].to_s != task.user_story_id.to_s and !UserStory.find(params[:user_story_id]).nil?
          task.user_story_id = params[:user_story_id]
        end
        if task.save
          log_task(task)
          render :update do |p|
#           p.replace_html("task_wrap_#{task.id}", "")
            @issue_statuses = IssueStatus.find(:all)
            p.insert_html :bottom, "tasks_#{task.status_id }_us_#{task.user_story_id}", :partial => "shared/task_view",
                        :locals => {:task => @issue, :issue_statuses => @issue_statuses}
          end
        end
#      end
    end
  end

  # PUT /tasks/1
  # PUT /tasks/1.xml
  def update
    @task = Task.find(params[:id])

    devs = []
    @task.users = []
    for developer in params[:task][:user_ids] do
      if developer != ""
        devs += [User.find(developer)]
      end
    end
    @task.users << devs
    @task.author = User.current
    
    if @task.update_attributes(params[:task])
      log_task(@task)
      redirect_to url_for_object(@task.user_story.sprint,@project,"show")
    else
      respond_to do |format|
        format.html { render :action => "edit" }
        format.xml  { render :xml => @task.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /tasks/1
  # DELETE /tasks/1.xml
  def destroy
    @task = Task.find(params[:id])
    @task.destroy

    respond_to do |format|
      format.html { redirect_to :back }
      format.xml  { head :ok }
    end
  end

  private
  def log_task(task)
    log = TaskLog.new
    log.user_id = User.current
    log.status_id= task.status_id
    log.task_id = task.id
    log.sprint_id = task.user_story.sprint.id
    log.save!
  end
  
  def find_project
    @project = Project.find(params[:project_id])
    rescue ActiveRecord::RecordNotFound
      render_404
  end
end
