module LicenseFinder
  class DecisionsFactory
    @decisions = {}

    class << self
      def decisions
        decisions_file_path = GlobalConfiguration.decisions_file
        if @decisions[decisions_file_path].nil?
          @decisions[decisions_file_path] = Decisions.fetch_saved(decisions_file_path)
        end
        @decisions[decisions_file_path]
      end
    end
  end
end
