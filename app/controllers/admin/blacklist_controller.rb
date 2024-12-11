class Admin::BlacklistController < Admin::BaseController
  def index
    list
    render_action 'list'
  end

  def list
    @blacklist_patterns = BlacklistPattern.all
  end

  def show
    @blacklist_pattern = BlacklistPattern.find(params[:id])
  end

  def new
    @blacklist_pattern = BlacklistPattern.new

    if params[:blacklist_pattern].has_key?('type')
      @blacklist_pattern = case params[:blacklist_pattern][:type]
        when "StringPattern": StringPattern.new
        when "RegexPattern": RegexPattern.new
      end
    end rescue nil

    @blacklist_pattern.attributes = params[:blacklist_pattern]
  end

  def create
    self.new() # Initialise @blacklist_pattern

    if @blacklist_pattern.save
      flash[:notice] = 'BlacklistPattern was successfully created.'
      redirect_to :action => 'list'
    else
      render :new
    end
  end

  def edit
    @blacklist_pattern = BlacklistPattern.find(params[:id])
    @blacklist_pattern.attributes = params[:blacklist_pattern]
  end

  def update
    self.edit() # Initialise @blacklist_pattern

    if @blacklist_pattern.save
      flash[:notice] = 'BlacklistPattern was successfully updated.'
      redirect_to :action => 'list'
    else
      render :edit
    end
  end

  def destroy
    @blacklist_pattern = BlacklistPattern.find(params[:id])
    if request.post?
      @blacklist_pattern.destroy
      redirect_to :action => 'list'
    end
  end

end
