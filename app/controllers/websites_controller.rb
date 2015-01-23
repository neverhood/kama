class WebsitesController < ApplicationController
  before_filter :find_website!, only: [ :edit, :destroy, :update, :show, :activate, :deactivate ]

  def index
    @websites = Website.all
    @website  = Website.new
  end

  def show
    @checks = @website.checks
  end

  def create
    @website = Website.create(website_params)

    if @website.persisted?
      render json: { website: render_to_string(partial: 'website', locals: { website: @website }) }, status: 202
    else
      render json: { errors: @website.errors }, status: 422
    end
  end

  def update
    if @website.update(website_params)
      redirect_to websites_path, notice: I18n.t('flash.websites.update.notice')
    else
      render :edit
    end
  end

  def destroy
    @website.destroy

    render nothing: true, status: 200
  end

  def activate
    @website.activate!

    render nothing: true, status: 200
  end

  def deactivate
    @website.deactivate!

    render nothing: true, status: 200
  end

  private

  def find_website!
    @website = Website.find(params[:id])
  end

  def website_params
    params.require(:website).permit(:url, :check_interval)
  end
end
