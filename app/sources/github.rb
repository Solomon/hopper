module Hopper
  class Github < Source
    # The name of the Source.
    #
    # Returns a String.
    def self.name
      "GitHub"
    end

    # The main URL of the Source.
    #
    # Returns a String.
    def self.url
      "https://github.com"
    end

    # The Git clone URL that lets us pull down this source.
    #
    # Returns a String.
    def clone_url
      "#{url}.git"
    end

    # THe clone command needed to clone down this source.
    #
    # Returns a String.
    def clone_command
      "git clone #{clone_url}"
    end
  end
end