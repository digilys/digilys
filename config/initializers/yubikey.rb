# Conf.yubikey can both be a boolean or a hash of
# settings. The last condition ensures that it's not
# a boolean.
if Conf.yubikey && !!Conf.yubikey != Conf.yubikey
  Yubikey.configure do |config|
    config.api_id  = Conf.yubikey.api_id  if Conf.yubikey.api_id
    config.api_key = Conf.yubikey.api_key if Conf.yubikey.api_key
  end

  if Conf.yubikey.url
    Kernel.silence_warnings do
      Yubikey::API_URL = Conf.yubikey.url
    end
  end
end

