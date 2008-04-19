desc 'Install dependencies'

def root_privileges_required!
  raise "Root privileges are required.\nPlease launch this task again as root." if ENV["USER"]!="root"
end

namespace :install_dependencies do
  # Not tested yet
  desc 'Install required packages on Debian'
  task :on_debian => :deb_packages


  # Tested successfully on 7.10 (gutsy)
  # odt2txt package not available on previous versions
  desc 'Install required packages on Ubuntu'
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
    #TODO: Should load this list from defined Filters
    packages=%w{antiword poppler-utils odt2txt html2text catdoc unrtf}.join(" ")
    puts "Installing "<<packages
    system("apt-get install "<<packages)
  end
end
