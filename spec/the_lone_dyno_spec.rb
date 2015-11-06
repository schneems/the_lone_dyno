require 'spec_helper'

describe TheLoneDyno do
  it 'has a version number' do
    expect(TheLoneDyno::VERSION).not_to be nil
  end

  it "runs on web process type by default" do
    begin
      web_log = new_log_file
      pid = Process.spawn("env DYNO=web.1 bundle exec ruby #{ fixture_path("once.rb") } >> #{web_log}")
      Process.wait(pid)

      expect_log_has_count(log: web_log, count: 1)
    ensure
      FileUtils.remove_entry_secure(web_log)
    end

    begin
      worker_log = new_log_file
      pid = Process.spawn("env DYNO=worker.1 bundle exec ruby #{ fixture_path("once.rb") } >> #{worker_log}")
      Process.wait(pid)

      expect_log_has_count(log: worker_log, count: 0)
    ensure
      FileUtils.remove_entry_secure(worker_log)
    end
  end

  it "runs in the syncronously when you want" do
    log = new_log_file
    pid = Process.spawn("env DYNO=web.1 bundle exec ruby #{ fixture_path("foreground.rb") } >> #{log}")
    Process.wait(pid)

    expect(File.read(log)).to eq("foreground 1\nforeground 2\n")
  end

  it "sends signals" do
    log = new_log_file
    begin

      pid = Process.spawn("env DYNO=web.1 bundle exec ruby #{ fixture_path("listen.rb") } >> #{log}")

      sleep 5
      TheLoneDyno.signal("hi there", key_base: testing_key("listen"))

      Process.wait(pid)

      expect_log_has_count(log: log, count: 1, msg: "hi there")
    ensure
      FileUtils.remove_entry_secure log
    end
  end

  it "only runs once" do
    begin
      log = new_log_file
      5.times.map do |i|
        Process.spawn("env DYNO=web.#{i} bundle exec ruby #{ fixture_path("once.rb") } >> #{log}")
      end.each do |pid|
        Process.wait(pid)
      end
      expect_log_has_count(log: log, count: 1)
    ensure
      FileUtils.remove_entry_secure log
    end
  end

  it "only runs X times" do
    begin
      count = rand(2..4)
      log   = new_log_file
      5.times.map do |i|
        Process.spawn("env DYNO=web.#{i} COUNT=#{count} bundle exec ruby #{ fixture_path("run_x_times.rb") } >> #{log}")
      end.each do |pid|
        Process.wait(pid)
      end
      expect_log_has_count(log: log, count: count)
    ensure
      FileUtils.remove_entry_secure log
    end
  end

end
