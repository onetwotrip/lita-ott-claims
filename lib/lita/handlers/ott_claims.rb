require 'chef/node'
require 'chef/search/query'

module Lita
  module Handlers
    class OttClaims < Lita::Handler
      config :chef_server_url, type: String
      config :chef_node_name, type: String
      config :chef_client_key_file, type: String
      config :claimable_entities, type: Hash

      route(/^claimlist(\s?\w*)/, :ottclaimlist, command: true, help: { 'Claims: claimlist' => 'show claimable environments' })
      route(/^claim(\s+\w*)/, :ottclaim, command: true, help: { 'Claims: claim' => 'claim environment' })
      route(/^unclaim(\s+\w*)/, :ottunclaim, command: true, help: { 'Claims: unclaim' => 'unclaim environment' })
      route(/^who claimed(\s+\w*)/, :ottclaim_exists?, command: true, help: { 'Claims: who claimed' => 'get current claimer for environment'})

      def claimable?(entity)
        Lita.config.handlers.ott_claims.claimable_entities.key?(entity)
      end

      def ottclaimlist(response)
        entity = response.args.first || ''
        chef_search = nil
        case entity
        when 'all', ''
          chef_search = Lita.config.handlers.ott_claims.claimable_entities.map { |_, v| v[:chef_search] }.join(' OR ')
        else
          if claimable?(entity.to_sym)
            chef_search = Lita.config.handlers.ott_claims.claimable_entities[entity.to_sym][:chef_search]
          end
        end

        list = []

        unless chef_search.nil? then
          Chef::Config[:chef_server_url] = Lita.config.handlers.ott_claims.chef_server_url
          Chef::Config[:node_name] = Lita.config.handlers.ott_claims.chef_node_name
          Chef::Config[:client_key] = Lita.config.handlers.ott_claims.chef_client_key_file

          query = Chef::Search::Query.new
          nodes = query.search('node', chef_search.to_s).first.sort

          nodes.each do |node|
            env_name = node.chef_environment.to_s
            claim_data = OttClaim.read(env_name)
            if claim_data
              list << "Env: #{env_name} - claimed by #{claim_data['claimer']} (since #{claim_data['timestamp']})"
            else
              list << "Env: #{env_name}"
            end
          end
        else
          list << "#{entity} is not claimable"
        end
        response.reply(list.join("\n"))
      end

      def ottclaim(response)
        claimer = response.message.source.user.name
        env_name = response.args.first
        if env_name && OttClaim.create(env_name, claimer)
          reply = "Ok, #{claimer}, claimed env #{env_name}"
        else
          existing_claimer = OttClaim.read(env_name)['claimer']
          reply = "Could not claim env #{env_name} - already claimed by #{existing_claimer}."
        end
        response.reply(reply)
      end

      def ottunclaim(response)
        unclaimer = response.message.source.user.name
        env_name = response.args.first

        if env_name && OttClaim.exists?(env_name)
          claimer = OttClaim.read(env_name)['claimer']
          if claimer == unclaimer
            OttClaim.destroy(env_name)
            reply = "Env #{env_name} is no longer claimed by #{claimer}"
          else
            reply = "Env #{env_name} is currently claimed by #{claimer}"
          end
        else
          reply = "Env #{env_name} has not yet been claimed."
        end
        response.reply(reply)
      end

      def ottclaim_exists?(response)
        env_name = response.args[1]
        if env_name && OttClaim.exists?(env_name)
          claim_data = OttClaim.read(env_name)
          reply = "Env #{env_name} is currently claimed by #{claim_data['claimer']} (since #{claim_data['timestamp']})"
        else
          reply = "Env #{env_name} has not been claimed."
        end
        response.reply(reply)
      end

      Lita.register_handler(self)
    end
  end
end
