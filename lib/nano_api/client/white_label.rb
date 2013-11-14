module NanoApi
  class Client
    module WhiteLabel
      def white_label host, preview=nil
        white_label_params = {signature: signature(nil, [preview, host].compact), white_label_host: host}
        white_label_params[:preview] = preview if preview

        get('white_labels/show', white_label_params, host_key: :travelpayouts_server)['white_label']
      end
    end
  end
end
