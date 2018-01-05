require_relative '../../support/feature_helper'
describe 'License Finder command line executable' do
  # As a developer
  # I want a command-line interface
  # So that I can manage my application's dependencies and licenses

  let(:developer) { LicenseFinder::TestingDSL::User.new }

  specify 'shows usage and subcommand help' do
    developer.create_empty_project

    developer.execute_command 'license_finder help'
    expect(developer).to be_seeing 'license_finder help [COMMAND]'

    developer.execute_command 'license_finder ignored_groups help add'
    expect(developer).to be_seeing 'license_finder ignored_groups add GROUP'
  end

  it "reports `license_finder`'s license is MIT" do
    developer.create_ruby_app # has license_finder as a dependency

    developer.run_license_finder
    expect(developer).to be_seeing_something_like(/license_finder.*MIT/)
  end

  it "reports dependencies' licenses" do
    developer.create_ruby_app # has license_finder as a dependency, which has thor as a dependency

    developer.run_license_finder
    expect(developer).to be_seeing_something_like(/thor.*MIT/)
  end

  specify 'runs default command' do
    developer.create_empty_project

    developer.run_license_finder
    expect(developer).to be_receiving_exit_code(0)
    expect(developer).to be_seeing 'No dependencies recognized!'
  end

  specify 'displays an error if project_path does not exist', :focus do
    developer.create_empty_project

    path = '/path/that/does/not/exist'
    developer.execute_command("license_finder report --project-path=#{path}")
    expect(developer).to be_seeing("Project path '#{File.absolute_path(path)}' does not exist!")
    expect(developer).to be_receiving_exit_code(1)
  end

  specify 'displays an error if symlink to potential license file is dangling' do
    project = LicenseFinder::TestingDSL::BrokenSymLinkDepProject.create
    ENV['GOPATH'] = "#{project.project_dir}/gopath_dep"
    developer.run_license_finder('gopath_dep/src/foo-dep')
    expect(developer).to be_seeing_something_like %r{ERROR: .*my_app/gopath_dep/src/foo-dep/vendor/a/b/LICENSE does not exist}
  end

  specify 'displays a warning if no package managers are active/installed' do
    developer.create_empty_project
    developer.execute_command('license_finder')
    expect(developer).to be_seeing('No active and installed package managers found for project.')
    expect(developer).to be_receiving_exit_code(0)
  end
end
