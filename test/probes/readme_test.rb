require File.expand_path("../../helper", __FILE__)

context "README" do
  setup do
    fixture :simple

    @project = Project.new('github.com')
    @probe = Readme.new(@project)

    @probe.stubs(:revision).returns('a965377486e0ad522f639bc2b4bcaa1032f92565')
  end

  test "count" do
    assert_equal 1, @probe.count
  end

  test "markdown_format_count" do
    assert_equal 1, @probe.markdown_format_count
  end
end