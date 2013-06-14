class NanoApi::Backends::ClicksController < NanoApi::ApplicationController
  respond_to :html, :js

  def show
    if @click_params = click_params
      render
    else
      render nothing: true, status: 404
    end
  end

  def link
    if @link_params = link_params
      redirect_to @link_params.try(:[], :url).presence
    else
      render nothing: true, status: 404
    end
  end

  def deeplink
    if @deeplink_params = deeplink_params
      render
    else
      render nothing: true, status: 404
    end
  end

private

  def click_params
    NanoApi.client.click(params[:search_id], params[:id],
      {:unique => _uniq_click?('c')})
  end

  def link_params
    NanoApi.client.link(params[:search_id], params[:id],
      {:unique => _uniq_click?('l')})
  end

  def deeplink_params
    NanoApi.client.deeplink(params[:search_id], params[:id],
      params.except(:id, :search_id).merge(:unique => _uniq_click?('l')))
  end

  def _uniq_click? scope, gate_id = _gate_id
    name = :"uc#{scope}#{gate_id}"
    clicked = cookies[name].present?
    cookies[name] = {
      :value => 1,
      :expires => 1.day.from_now
    } unless clicked
    clicked ? '0' : '1'
  end

  def _gate_id
    params[:gate_id]
  end

end
