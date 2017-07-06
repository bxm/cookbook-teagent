#
# Cookbook Name:: teagent
# Recipe:: default
#
# Copyright 2013, ThousandEyes, Inc.
#

if node['teagent']['set_repo']
    include_recipe 'teagent::dependency'
end

unless node['teagent']['package'].has_key?('te-agent')
    node['teagent']['package']['te-agent'] = true
end

node['teagent']['package'].each do |pkg,ver|

    next unless pkg.match(/^te-/) # stop other installs piggy backing

    package pkg do
        if (ver or pkg == 'te-agent') # always install te-agent
            if ver.to_s.match(/^latest$/)
                action :upgrade
            else
                action :install
                version ver.to_s if vers.match(/^([0-9]+[.]){2,}[0-9]+-[1-9][0-9]*$/)
            end
            allow_downgrade true
            notifies(:run, 'execute[config_teagent.sh]', :delayed) if pkg == 'te-agent'
        else
            action :delete
        end
    end

end

template '/var/lib/te-agent/config_teagent.sh' do
    source 'config_teagent.sh.erb'
    mode '0755'
    owner 'root'
    group 'root'
    variables({
        :real_account_token => node['teagent']['account_token'],
        :real_log_path => node['teagent']['log_path'],
        :real_proxy_host => node['teagent']['proxy_host'],
        :real_proxy_port => node['teagent']['proxy_port'],
        :real_proxy_user => node['teagent']['proxy_user'],
        :real_proxy_pass => node['teagent']['proxy_pass'],
        :real_ip_version => node['teagent']['ip_version'],
        :real_interface  => node['teagent']['interface'],
    })
    action :create
    notifies :run, "execute[config_teagent.sh]", :delayed
end

execute 'config_teagent.sh' do
    command '/var/lib/te-agent/config_teagent.sh'
    action :nothing
    notifies :restart, 'service[te-agent]', :delayed
end

include_recipe 'teagent::service'
