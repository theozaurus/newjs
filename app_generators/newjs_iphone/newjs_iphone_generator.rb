class NewjsIphoneGenerator < RubiGen::Base
  DEFAULT_SHEBANG = File.join(Config::CONFIG['bindir'],
                              Config::CONFIG['ruby_install_name'])

  default_options :shebang => DEFAULT_SHEBANG,
                  :author => nil,
                  :email       => nil,
                  :version     => '0.0.1'


  attr_reader :name, :module_name
  attr_reader :version, :version_str, :author, :email
  attr_reader :title, :url


  def initialize(runtime_args, runtime_options = {})
    super
    usage if args.empty?
    @destination_root = File.expand_path(args.shift)
    @name = base_name
    @module_name = name.camelize
    extract_options
    @title ||= @name.titleize
    @url   ||= "http://NOTE-ENTER-URL.com"
  end

  def manifest
    script_options = { :chmod => 0755, :shebang => options[:shebang] == DEFAULT_SHEBANG ? nil : options[:shebang] }
    windows        = (RUBY_PLATFORM =~ /dos|win32|cygwin/i) || (RUBY_PLATFORM =~ /(:?mswin|mingw)/)

    record do |m|
      # Ensure appropriate folder(s) exists
      m.directory ''
      BASEDIRS.each { |path| m.directory path }

      m.file_copy_each %w[unittest.css jsunittest.js], "Html/test/assets"
      m.file_copy_each %w[javascript_test_autotest_tasks.rake], "Html/tasks"
      m.file_copy_each %w[javascript_test_autotest.yml.sample], "Html/config"
      m.file_copy_each %w[protodoc.rb jstest.rb], "Html/lib"
      m.template_copy_each %w[Rakefile.erb], "Html"
      m.template "Html/src/library.js.erb", "Html/src/#{name}.js.erb"

      %w[rstakeout js_autotest].each do |file|
        m.template "Html/script/#{file}",        "Html/script/#{file}", script_options
        m.template "Html/script/win_script.cmd", "Html/script/#{file}.cmd",
          :assigns => { :filename => file } if windows
      end

      m.dependency "install_rubigen_scripts",
        [File.join(destination_root, "Html"), 
          'javascript', 'javascript_test', 'newjs_iphone', 'newjs_theme'],
          :shebang => options[:shebang], :collision => :force
    end
  end

  protected
    def banner
      <<-EOS
Creates a JavaScript project.

USAGE: #{spec.name} name"
EOS
    end

    def add_options!(opts)
      opts.separator ''
      opts.separator 'Options:'
      # For each option below, place the default
      # at the top of the file next to "default_options"
      opts.on("-a", "--author=\"Your Name\"", String,
              "Default: none") { |x| options[:author] = x }
      opts.on("-e", "--email=\"your@email.com\"", String,
              "Your email to be inserted into generated files.",
              "Default: ~/.rubyforge/user-config.yml[email]") { |x| options[:email] = x }
      opts.on("-t", "--title=\"Project Title\"", String,
              "Human-readable/marketing name for project.",
              "Default: Project Name") { |x| options[:title] = x }
      opts.on("-u", "--url=\"http://url-to-project.com\"", String,
              "Default: http://NOTE-ENTER-URL.com") { |x| options[:url] = x }
      opts.on("-v", "--version", "Show the #{File.basename($0)} version number and quit.")
      opts.on("-V", "--set-version=X.Y.Z", String,
              "Initial version of the project you are creating.",
              "Default: 0.0.1") { |x| options[:version] = x }
    end

    def extract_options
      @version           = options[:version].to_s.split(/\./)
      @version_str       = @version.join('.')
      @author            = options[:author]
      @email             = options[:email]
      unless @author && @email
        require 'newjs/rubyforge'
        rubyforge_config = Newjs::Rubyforge.new
        @author ||= rubyforge_config.full_name
        @email  ||= rubyforge_config.email
      end
      @url               = options[:url]
    end

    # Installation skeleton.  Intermediate directories are automatically
    # created so don't sweat their absence here.
    BASEDIRS = %w(
      Html/config
      Html/lib
      Html/src
      Html/script
      Html/tasks
      Html/test/assets
      Html/test/unit
    )
end