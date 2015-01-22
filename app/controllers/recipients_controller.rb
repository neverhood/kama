class RecipientsController < ApplicationController
  before_filter :find_recipient!, only: [ :edit, :destroy, :update ]

  def index
    @recipients = Recipient.all
    @recipient  = Recipient.new
  end

  def create
    @recipient = Recipient.create(recipient_params)

    if @recipient.persisted?
      render json: { recipient: render_to_string(partial: 'recipient', locals: { recipient: @recipient }) }, status: 202
    else
      render json: { errors: @recipient.errors }, status: 422
    end
  end

  def update
    if @recipient.update(recipient_params)
      redirect_to recipients_path, notice: I18n.t('flash.recipients.update.notice')
    else
      render :edit
    end
  end

  def destroy
    @recipient.destroy

    render nothing: true, status: 200
  end

  private

  def find_recipient!
    @recipient = Recipient.find(params[:id])
  end

  def recipient_params
    params.require(:recipient).permit(:name, :email)
  end
end
