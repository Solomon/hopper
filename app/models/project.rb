require 'digest/sha1'

module Hopper
  # A collection of code that we grab from somewhere. This is our common
  # interface for manipulating the project itself once we have it locally.
  #
  # Redis Keys:
  #
  #   hopper:projects - All of the Project URLs.
  class Project
    # Set Project up in resque to run under the "index" queue.
    @queue = :index

    # The ID of the Project.
    #
    # Returns a String (the sha).
    attr_accessor :id

    # Set the URL of the project. Removes www., removes http(s) protocol.
    #
    # Returns a String.
    def url=(url)
      host = URI.parse(url).host
      path = URI.parse(url).path
      url  = "#{host}#{path}"

      @url = url.gsub(/^www\./,'')
    end

    # The URL of the project.
    #
    # Returns a String.
    attr_reader :url

    # Initializes a new Project.
    #
    # path - The String path to this project.
    def initialize(url)
      @url = url
      @id  = sha1
    end

    # Initializes and saves a new Project.
    #
    # Returns the Project.
    def self.create(url)
      project = new(url)
      project.save
      project
    end

    # Finds a Project from an ID.
    #
    # Returns the Project.
    def self.find(id)
      hash = $redis.hgetall("#{Project.key}:#{id}")
      new(hash['url'])
    end

    # The main redis key.
    #
    # Returns a String.
    def self.key
      "#{Hopper.redis_namespace}:projects"
    end

    # The method Resque uses to asynchronously do the dirty.
    #
    # id - The ID of the Project.
    #
    # Returns whatever Resque returns.
    def self.perform(id)
      Project.find(id).analyze
    end

    # Queue up a job to analyze this project.
    #
    # Returns a boolean.
    def async_analyze
      Resque.enqueue(Project, self.id)
    end

    # All Projects.
    #
    # Returns an Array.
    def self.all
      $redis.smembers key
    end

    # The SHA1 representation of the URL.
    #
    # Returns a String.
    def sha1
      Digest::SHA1.hexdigest url
    end

    # An URL. Just assume HTTP for now.
    #
    # Returns a String.
    def url_with_protocol
      "https://#{url}"
    end

    # Accesses the Source for this Project.
    #
    # Returns a Source.
    def source
      Source.new_from_url(url)
    end

    # Saves the project to the database.
    #
    # Returns nothing.
    def save
      async_analyze

      $redis.sadd Project.key, id

      hash_id = "#{Project.key}:#{id}"
      $redis.hset hash_id, :url, url
    end

    # The path to this project on-disk.
    #
    # Returns a String.
    def path
      source.local_path
    end

    # All files in this project.
    #
    # Returns an Array of String paths.
    def files
      Dir.glob("#{path}/**/*")
    end

    # All Ruby files in this project.
    #
    # Returns an Array of String paths.
    def ruby_files
      Dir.glob("#{path}/**/*.rb")
    end

    # All of the contents of each file in this project.
    #
    # Returns an Array of Strings.
    def file_contents
      files.map do |file|
        File.directory?(file) ? '' : File.read(file)
      end
    end

    # All of the contents of each Ruby file in this project.
    #
    # Returns an Array of Strings.
    def ruby_file_contents
      ruby_files.map do |file|
        File.directory?(file) ? '' : File.read(file)
      end
    end

    # The entire project as one big String. Yeah, we'll go with that for now.
    #
    # Returns a String.
    def file_contents_string
      file_contents.join("\n")
    end

    # All Ruby project files as one big String.
    #
    # Returns a String.
    def ruby_contents_string
      ruby_file_contents.join("\n")
    end

    # Access this project's probes (which should be all probes available).
    #
    # Returns an Array of Probe instances.
    def probes
      Probe.all.collect do |probe|
        probe.new(self)
      end
    end

    # The Great Bambino. Runs through all Probes and gives us an analysis of
    # this Project.
    #
    # Returns nothing.
    def analyze
      source.clone
      Probe.analyze(self)
    end
  end
end