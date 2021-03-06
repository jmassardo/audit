# encoding: utf-8
require 'json'
require_relative '../helper'
require_relative './automate'

module Reporter
  #
  # Used to send inspec reports to Chef Automate server via Chef Server
  #
  class ChefServerAutomate < ChefAutomate
    def initialize(opts)
      @entity_uuid           = opts[:entity_uuid]
      @run_id                = opts[:run_id]
      @node_name             = opts[:node_info][:node]
      @insecure              = opts[:insecure]
      @environment           = opts[:node_info][:environment]
      @roles                 = opts[:node_info][:roles]
      @recipes               = opts[:node_info][:recipes]
      @url                   = opts[:url]
      @chef_tags             = opts[:node_info][:chef_tags]
      @policy_group          = opts[:node_info][:policy_group]
      @policy_name           = opts[:node_info][:policy_name]
      @source_fqdn           = opts[:node_info][:source_fqdn]
      @organization_name     = opts[:node_info][:organization_name]
      @ipaddress             = opts[:node_info][:ipaddress]
      @fqdn                  = opts[:node_info][:fqdn]
      @control_results_limit = opts[:control_results_limit]
    end

    def send_report(report)
      unless @entity_uuid && @run_id
        Chef::Log.error "entity_uuid(#{@entity_uuid}) or run_id(#{@run_id}) can't be nil, not sending report to Chef Automate"
        return false
      end

      automate_report = truncate_controls_results(enriched_report(report), @control_results_limit)

      report_size = automate_report.to_json.bytesize
      # this is set to slightly less than the oc_erchef limit
      if report_size > 900 * 1024
        Chef::Log.warn "Compliance report size is #{(report_size / (1024 * 1024.0)).round(2)} MB."
        Chef::Log.warn 'Infra Server < 13.0 defaults to a limit of ~1MB, 13.0+ defaults to a limit of ~2MB.'
      end

      if @insecure
        Chef::Config[:verify_api_cert] = false
        Chef::Config[:ssl_verify_mode] = :verify_none
      end

      Chef::Log.info "Report to Chef Automate via Chef Server: #{@url}"
      rest = Chef::ServerAPI.new(@url, Chef::Config)
      with_http_rescue do
        rest.post(@url, automate_report)
        return true
      end
      false
    end
  end
end
