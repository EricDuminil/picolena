desc 'Install dependencies'

def root_privileges_required!
  raise "Root privileges are required.\nPlease launch this task again as root." if ENV["USER"]!="root"
end

namespace :install_dependencies do
  # Not tested yet
  desc 'Install required gems and packages on Debian'
  task :on_debian => [:gems, :deb_packages]


  # Tested successfully on 7.10 (gutsy)
  # odt2txt package not available on previous versions
  desc 'Install required gems and packages on Ubuntu'
  task :on_ubuntu => :on_debian
  
  desc 'Install required gems and programs on Windows'
  task :on_windows_xp do
    #NOTE: Long way to go before it runs on XP.
    $stderr.puts "Implement me!"
  end

  desc 'Install required gems and packages on Mac Os'  
  task :on_mac_os do
    $stderr.puts "Implement me!"
  end

  desc 'Install required .deb packages'
  task :deb_packages do
    root_privileges_required!
    packages=%w{antiword poppler-utils odt2txt html2text catdoc unrtf}.join(" ")
    puts "Installing "<<packages
    system("apt-get install "<<packages)
  end

  desc 'Install required gems'  
  task :gems do
    root_privileges_required!
    required_gems=%w{ferret paginator}
    puts "Installing required gems : "<<required_gems.join(", ")
    required_gems.each do |gem_name|
      begin
        gem gem_name
        puts "\t#{gem_name} already installed"
      rescue NameError
        system("gem install #{gem_name}")
      end
    end
  end
end