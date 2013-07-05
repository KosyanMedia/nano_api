module NanoApi
  class Client
    module WhiteLabel
      def white_label host
        get('white_labels/show', signature: signature(nil, [host]), white_label_host: host)['white_label']
      end
    end
  end
end
