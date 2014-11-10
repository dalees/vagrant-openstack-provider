require 'log4r'
require 'restclient'
require 'json'

require 'vagrant-openstack-provider/client/http_utils'
require 'vagrant-openstack-provider/client/domain'

module VagrantPlugins
  module Openstack
    class NeutronClient
      include Singleton
      include VagrantPlugins::Openstack::HttpUtils
      include VagrantPlugins::Openstack::Domain

      def initialize
        @logger = Log4r::Logger.new('vagrant_openstack::neutron')
        @session = VagrantPlugins::Openstack.session
      end

      def get_api_version_list(_env)
        json = RestClient.get(@session.endpoints[:network], 'X-Auth-Token' => @session.token, :accept => :json) do |response|
          log_response(response)
          case response.code
          when 200, 300
            response
          when 401
            fail Errors::AuthenticationFailed
          else
            fail Errors::VagrantOpenstackError, message: response.to_s
          end
        end
        JSON.parse(json)['versions']
      end

      def get_private_networks(env)
        get_networks(env, false)
      end

      def get_all_networks(env)
        get_networks(env, true)
      end

      def get_subnets(env)
        subnets_json = get(env, "#{@session.endpoints[:network]}/subnets")
        subnets = []
        JSON.parse(subnets_json)['subnets'].each do |n|
          subnets << Subnet.new(n['id'], n['name'], n['cidr'], n['enable_dhcp'], n['network_id'])
        end
        subnets
      end

      private

      def get_networks(env, all)
        networks_json = get(env, "#{@session.endpoints[:network]}/networks")
        networks = []
        JSON.parse(networks_json)['networks'].each do |n|
          networks << Item.new(n['id'], n['name']) if all || n['tenant_id'].eql?(@session.project_id)
        end
        networks
      end
    end
  end
end
