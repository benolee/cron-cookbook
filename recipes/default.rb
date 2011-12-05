untag("nagios-CRON")

case node[:platform]
when 'gentoo'
  portage_package_keywords "=sys-process/dcron-4.5"
  %w(sys-process/dcron dev-util/lockrun).each do |p|
    package p
  end

  template "/etc/conf.d/dcron" do
    source "dcron.confd.erb"
    mode "0644"
    notifies :restart, "service[dcron]"
  end

  service "dcron" do
    action [:enable, :start]
  end
when 'centos'
  %w(vixie-cron hatools).each do |p|
    package p
  end

  service "crond" do
    action [:enable, :start]
  end
end

%w(d hourly daily weekly monthly).each do |dir|
  directory "/etc/cron.#{dir}" do
    mode "0750"
  end
end

file "/etc/crontab" do
  action :delete
  backup 0
end

monit_config "cron" do
  cookbook "cron"
  source "monit.erb"
end

cron "lastrun-hourly" do
  minute node[:cron][:hourly][:minute]
  command "rm -f /var/spool/cron/lastrun/cron.hourly"
end

cron "lastrun-daily" do
  minute node[:cron][:daily][:minute]
  hour node[:cron][:daily][:hour]
  command "rm -f /var/spool/cron/lastrun/cron.daily"
end

cron "lastrun-weekly" do
  minute node[:cron][:weekly][:minute]
  hour node[:cron][:weekly][:hour]
  weekday node[:cron][:weekly][:wday]
  command "rm -f /var/spool/cron/lastrun/cron.weekly"
end

cron "lastrun-monthly" do
  minute node[:cron][:monthly][:minute]
  hour node[:cron][:monthly][:hour]
  day node[:cron][:monthly][:wday]
  command "rm -f /var/spool/cron/lastrun/cron.monthly"
end

cron "run-crons" do
  minute "*/10"
  command "/usr/bin/test -x /usr/sbin/run-crons && /usr/sbin/run-crons"
end

if tagged?("nagios-client")
  cron "heartbeat" do
    command "/usr/bin/touch /tmp/.check_cron"
  end

  nagios_plugin "cron" do
    source "check_cron"
  end

  nrpe_command "check_cron" do
    command "/usr/lib/nagios/plugins/check_cron"
  end

  nagios_service "CRON" do
    check_command "check_nrpe!check_cron"
    servicegroups "system"
  end
end
