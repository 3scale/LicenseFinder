module LicenseFinder
  class LicenseAggregator
    def initialize(project_config, aggregate_paths)
      @project_config = project_config
      @aggregate_paths = aggregate_paths
    end

    def dependencies
      aggregate_packages
    end

    def any_packages?
      finders.map do |finder|
        finder.prepare_projects if GlobalConfiguration.prepare
        finder.any_packages?
      end.reduce(:|)
    end

    def unapproved
      aggregate_packages.reject(&:approved?)
    end

    def blacklisted
      aggregate_packages.select(&:blacklisted?)
    end

    private

    def finders
      return @finders unless @finders.nil?
      @finders = if @aggregate_paths.nil?
                   [LicenseFinder::Core.new(@project_config)]
                 else
                   @aggregate_paths.map do |path|
                     LicenseFinder::Core.new(ProjectConfiguration.new(path))
                   end
                 end
    end

    def aggregate_packages
      return @packages unless @packages.nil?
      all_packages = finders.flat_map do |finder|
        finder.prepare_projects if GlobalConfiguration.prepare
        finder.acknowledged.map { |dep| MergedPackage.new(dep, [finder.project_path]) }
      end
      @packages = all_packages.group_by { |package| [package.name, package.version] }
                              .map do |_, packages|
        MergedPackage.new(packages[0].dependency, packages.flat_map(&:aggregate_paths))
      end
    end
  end
end
