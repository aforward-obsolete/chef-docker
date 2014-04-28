
group "docker" do
  action :create
  members "#{node[:docker][:user]}"
  append true
end

[
  "apt-get update",
  "apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9",
  "sh -c \"echo deb http://get.docker.io/ubuntu docker main\\\n> /etc/apt/sources.list.d/docker.list\"",
  "apt-get update",
  "apt-get install -y lxc-docker",
].each do |cmd|
  execute "#{cmd}" do
    not_if { File.exists?("#{node[:docker][:bin]}") }
  end
end

allow_verb = node[:docker][:allow_incoming_connections] ? "allow" : "deny"
execute "ufw #{allow_verb} #{node[:docker][:port]}/tcp" 

# ENABLE ACCESS WHEN USING UFW
if node[:docker][:enable_ufw]

  execute "cp #{node[:docker][:ufw_path]} #{node[:docker][:ufw_path]}.orig" do
    only_if { File.exists?("#{node[:docker][:ufw_path]}") && !File.exists?("#{node[:docker][:ufw_path]}.orig") }
  end

  template "#{node[:docker][:ufw_path]}" do
    owner "root"
    group "root"
    mode 0644
    source 'ufw.erb'
    notifies :run, "execute[ufw reload]"
  end

  execute "ufw reload" do
    action :nothing
  end

# DISABLE UFW ROUTING AND RETURN TO ORIGINAL STATE
else
  execute "cp #{node[:docker][:ufw_path]}.orig #{node[:docker][:ufw_path]}" do
    only_if { File.exists?("#{node[:docker][:ufw_path]}.orig") }
  end
end

directory "#{node[:docker][:src]}" do
  recursive true
end

node[:docker][:installs].each do |name,giturl|

  parent_dir = name.split("/")[0...-1].join("/")
  unless parent_dir == ""
    directory "#{node[:docker][:src]}/#{parent_dir}" do
      recursive true
    end
  end

  git "#{node[:docker][:src]}/#{name}" do
    repository "#{giturl}"
    reference "master"
    depth 1
    notifies :run, "execute[docker build #{name}]"
  end

  execute "docker build #{name}"  do
    cwd "#{node[:docker][:src]}/#{name}"
    command "docker build -t=\"#{name}\" ."
    action :nothing
  end

end
