class Admin::ResourcesController < Admin::BaseController
  include UploadProgress::UploadProgressConcern
  upload_status_for :upload, :upload_status

  def index
    list
    render :action => 'list'
  end

  def list
    @r = Resource.new
    @itunes_category_list = @r.get_itunes_categories
    @resources_pages, @resources = pagy_with_params(scope: Resource.order(created_at: :desc))
  end

  def new
  end

  # Custom route which in a modern implementation ought to be #create.
  #
  def upload
    begin
      file = params[:upload][:filename]
      @up = Resource.create(:filename => file.original_filename, :mime => file.content_type.chomp, :created_at => Time.now)

      @up.write_to_disk(file)

      @message = 'File uploaded: '+file.size.to_s
      finish_upload_status "'#{@message}'"
    rescue
      @message = "'Unable to upload #{file.original_filename}'"
      @up.destroy unless @up.nil?
      raise
    end
  end

  def update
    @resource = Resource.find(params[:resource][:id])
    @resource.attributes = params[:resource]

    unless params[:itunes_category].nil?
      itunes_categories = params[:itunes_category]
      itunes_category_pre = Hash.new {|h, k| h[k] = [] }
      itunes_categories.each do |cat|
        cat_split = cat.split('-')
        itunes_category_pre[cat_split[0]] << cat_split[1] unless
        itunes_category_pre[cat_split[0]].include?(cat_split[0])
      end
      @resource.itunes_category = itunes_category_pre
    end

    if request.post? and @resource.save
      flash[:notice] = 'Metadata was successfully updated.'
    else
      flash[:error] = 'Not all metadata was defined correctly.'
      @resource.errors.each do |meta_key,val|
        flash[:error] << "<br />" + val
      end
    end

    redirect_to :action => 'index'
  end

  def destroy
    @file = Resource.find(params[:id])
    @file.destroy

    redirect_to :action => 'index'
  end

  def remove_itunes_metadata
    @resource = Resource.find(params[:id])
    @resource.itunes_metadata = false
    @resource.save(false)

    flash[:notice] = 'Metadata was successfully removed.'
    redirect_to :action => 'index'
  end

  def set_mime
    @resource = Resource.find(params[:resource][:id])
    @resource.mime = params[:resource][:mime] unless params[:resource][:mime].empty?

    if request.post? and @resource.save
      flash[:notice] = 'Content Type was successfully updated.'
    else
      flash[:error] = "Error occurred while updating Content Type."
    end

    redirect_to :action => "index"
  end

  def upload_status
    render :inline => "<%= upload_progress.completed_percent rescue 0 %> % complete", :layout => false
  end
end
