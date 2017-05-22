#!/usr/bin/env ruby

require 'spf'
require 'spf/query'
require 'pry'

class SpfChecker
  SPF_VERSIONS = [1, 2]  # optional
  Result = Struct.new(:is_included, :record, :code) do
    def valid?
      is_included && code == :pass
    end

    def to_s
      "valid: #{valid?}, record: #{record}"
    end
  end

  def initialize(spf_domain_to_include: , mail_server_ip:)
    @spf_domain_to_include = spf_domain_to_include
    @mail_server_ip = mail_server_ip
  end

  def check(domain)
    Result.new(
      spf_included?(domain),
      spf_record(domain),
      validate_spf('info@' + domain)
    )
  end

  private

  attr_accessor :spf_domain_to_include, :mail_server_ip

  def spf_server
    @spf_server ||= SPF::Server.new
  end

  def spf_record(domain)
    SPF::Query::Record.query(domain).to_s
  rescue SPF::Query::InvalidRecord => e
    "Error: #{e.message}"
  end

  def validate_spf(identity)
    request = SPF::Request.new(
      versions:      SPF_VERSIONS,
      identity:      identity,
      ip_address:    mail_server_ip
    )

    result = spf_server.process(request)

    result.code # :pass, :fail, etc.
  end

  def spf_included?(domain)
    res = SPF::Query::Record.query domain
    !!res.include.find { |i| i.value == spf_domain_to_include }
  rescue SPF::Query::InvalidRecord
    false
  end
end


checker = SpfChecker.new( spf_domain_to_include: '_spf.kiiiosk.ru',  mail_server_ip: '136.243.75.105')

%w(hello-oils.ru wanna-be.ru yopage.ru kiiiosk.ru _spf-ipv4.kiiiosk.ru).each do |domain|
  res = checker.check domain
  puts "#{domain}: #{res}"
end
