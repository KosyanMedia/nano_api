module NanoApi::Client::WhiteLabel
  def white_label host
    get('white_labels/show', signature: signature(nil, [host]), white_label_host: host)
  end
end
