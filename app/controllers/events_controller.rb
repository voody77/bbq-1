class EventsController < ApplicationController
  before_action :authenticate_user!, except: [:show, :index]

  before_action :set_event, only: [:show]

  #before_action :set_current_user_event, only: [:edit, :update, :destroy]

  before_action :password_guard!, only: [:show]
  skip_before_action :verify_authenticity_token

  after_action :verify_authorized, only: [:edit, :update, :destroy, :show]

  def index
    @events = Event.all
  end

  def show
    authorize @event
    @new_comment = @event.comments.build(params[:comment])
    @new_subscription = @event.subscriptions.build(params[:subscription])
    # Болванка модели для формы добавления фотографии
    @new_photo = @event.photos.build(params[:photo])
  end

  def new
    @event = current_user.events.build
  end

  def edit
  end

  def create
    @event = current_user.events.build(event_params)
    authorize @event

    if @event.save
      redirect_to @event, notice: t('controllers.events.created')
    else
      render :new
    end
  end

  def update
    if @event.update(event_params)
      authorize @event
      redirect_to @event, notice: t('controllers.events.updated')
    else
      render :edit
    end
  end

  def destroy
    @event.destroy
    authorize @event
    redirect_to events_url, notice: t('controllers.events.destroyed')
  end

  private

  def set_current_user_event
    @event = current_user.events.find(params[:id])
  end

  def set_event
    @event = Event.find(params[:id])
  end

  def event_params
    params.require(:event).permit(:title, :address, :datetime, :description, :pincode)
  end

  def password_guard!
    return true if @event.pincode.blank?
    return true if signed_in? && current_user == @event.user

    if params[:pincode].present? && @event.pincode_valid?(params[:pincode])
      cookies.permanent["events_#{@event.id}_pincode"] = params[:pincode]
    end

    pincode = cookies.permanent["events_#{@event.id}_pincode"]
    unless @event.pincode_valid?(pincode)
      if params[:pincode].present?
        flash.now[:alert] = I18n.t('controllers.events.wrong_pincode')
      end
      render 'password_form'
    end
  end
end
