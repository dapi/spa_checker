#!/usr/bin/env ruby

require 'spf'
require 'spf/query'
require 'pry'

KIOSK_IP = '136.243.75.105' # Адрес сервера srv-1.kiiiosk.ru с которого отправляются письма
# KIOSK_IP = '2a01:4f8:212:295d::2' # Адрес сервера srv-1.kiiiosk.ru с которого отправляются письма
KIOSK_SPF = '_spf.kiiiosk.ru'

def validate_spf(domain)
	spf_server = SPF::Server.new

	request = SPF::Request.new(
		versions:      [1, 2],             # optional
		identity:      'info@' + domain,
		ip_address:    KIOSK_IP
	)

	result = spf_server.process(request)

	result.code # :pass, :fail, etc.
end

def check_spf(domain)
	SPF::Query::Record.query domain
rescue SPF::Query::InvalidRecord
  ''
end

def include_kiosk?(domain)
  res = SPF::Query::Record.query domain
  !!res.include.find { |i| i.value == KIOSK_SPF }
rescue SPF::Query::InvalidRecord
  false
end

%w(hello-oils.ru wanna-be.ru yopage.ru kiiiosk.ru _spf-ipv4.kiiiosk.ru).each do |domain|
  puts "Домен #{domain}"
  result = validate_spf(domain)
  spf = check_spf(domain)
  i = include_kiosk?(domain)
  puts "\t#{result}: #{spf}"
  puts "\tInclude kiosk: #{i}"
end
