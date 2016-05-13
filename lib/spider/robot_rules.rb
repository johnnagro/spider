#!/usr/local/bin/ruby -w

# robot_rules.rb
#
#  Created by James Edward Gray II on 2006-01-31.
#  Copyright 2006 Gray Productions. All rights reserved.

require "uri"

# Based on Perl's WWW::RobotRules module, by Gisle Aas.
class RobotRules
   def initialize( user_agent )
     @user_agent = user_agent.scan(/\S+/).first.sub(%r{/.*},
"").downcase
     @rules      = Hash.new { |rules, rule| rules[rule] = Array.new }
   end

   def parse( text_uri, robots_data )
     uri      = URI.parse(text_uri)
     location = "#{uri.host}:#{uri.port}"
     @rules.delete(location)

     rules      = robots_data.split(/[\015\012]+/).
                              map { |rule| rule.sub(/\s*#.*$/, "") }
     anon_rules = Array.new
     my_rules   = Array.new
     current    = anon_rules
     rules.each do |rule|
       case rule
       when /^\s*User-Agent\s*:\s*(.+?)\s*$/i
         break unless my_rules.empty?

         current = if $1 == "*"
           anon_rules
         elsif $1.downcase.index(@user_agent)
           my_rules
         else
           nil
         end
       when /^\s*Disallow\s*:\s*(.*?)\s*$/i
         next if current.nil?

         if $1.empty?
           current << nil
         else
           disallow = URI.parse($1)

           next unless disallow.scheme.nil? or disallow.scheme ==
uri.scheme
           next unless disallow.port.nil?   or disallow.port == uri.port
           next unless disallow.host.nil?   or
                       disallow.host.downcase == uri.host.downcase

           disallow = disallow.path
           disallow = "/"            if disallow.empty?
           disallow = "/#{disallow}" unless disallow[0] == ?/

           current << disallow
         end
       end
     end

     @rules[location] = if my_rules.empty?
       anon_rules.compact
     else
       my_rules.compact
     end
   end

   def allowed?( text_uri )
     uri      = URI.parse(text_uri)
     location = "#{uri.host}:#{uri.port}"
     path     = uri.path

     return true unless %w{http https}.include?(uri.scheme)

     not @rules[location].any? { |rule| path.index(rule) == 0 }
   end
end
