#Deny all, Allow only IPs described in config/custom/white_list_ip.yml
white_list_ip_config_file='config/custom/white_list_ip.yml'
WhiteListIPs=Regexp.new(
    "^("<<
      YAML.load_file(white_list_ip_config_file)["Allow"].collect{|ip|
        ip.downcase.include?("all") ? /.*/ : Regexp.escape(ip)
      }.join("|")<<")"
  ) rescue /^(127\.0\.0\.1|0\.0\.0\.0)/