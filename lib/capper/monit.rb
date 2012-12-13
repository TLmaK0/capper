set(:monitrc) { "#{deploy_to}/.monitrc.local" }
set(:monit_user) { nil }

after "deploy:update_code", "monit:setup"
before "deploy:restart", "monit:reload"

namespace :monit do
  desc "Setup monit configuration files"
  task :setup do
    configs = fetch(:monit_configs, {})
    servers = find_servers

    upload_template(monitrc, :mode => "0644") do |server|
      configs.select do |name, config|
        roles = config[:options][:roles]
        if roles.nil?
          true
        else
          [roles].flatten.select do |r|
            self.roles[r.to_sym].include?(server)
          end.any?
        end
      end.map do |name, config|
        "# #{name}\n#{config[:body]}"
      end.join("\n\n")
    end
  end

  desc "Reload monit configuration"
  task :reload do    
    sudo_run = "sudo -u #{monit_user} " if monit_user
    run "#{sudo_run if monit_user}monit reload &>/dev/null && sleep 1"
  end
end
