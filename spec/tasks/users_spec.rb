require "rails_helper"
require "rake"

RSpec.describe "UserTasks" do
  before(:all) { Rails.application.load_tasks if Rake::Task.tasks.empty? } # rubocop:disable RSpec/BeforeAfterAll

  # Runs a task with the lines typed at its prompts, and gives what it printed.
  def run_task(name, *lines)
    output = StringIO.new
    original = [$stdin, $stdout, $stderr]
    $stdin = StringIO.new(lines.map { |line| "#{line}\n" }.join)
    $stdout = $stderr = output
    Rake::Task[name].reenable
    Rake::Task[name].invoke
    [output.string, true]
  rescue SystemExit => error
    [output.string, error.success?]
  ensure
    $stdin, $stdout, $stderr = original
  end

  describe "users:create" do
    it "creates one user" do
      output, success = run_task("users:create", "Owner@example.com", "correct horse", "correct horse")

      expect(success).to be(true)
      expect(output).not_to include("correct horse")
      expect(User.authenticate_by(email_address: "owner@example.com", password: "correct horse")).to eq(User.sole)
    end

    it "refuses a second before asking anything" do
      create(:user)
      output, success = run_task("users:create", "second@example.com", "correct horse", "correct horse")

      expect(success).to be(false)
      expect(output).to include("already exists")
      expect(output).not_to include("Password")
      expect(User.count).to eq(1)
    end

    it "refuses a bad address, a short password and a different confirmation" do
      [["nobody", "correct horse", "correct horse"], ["a@example.com", "short", "short"],
       ["a@example.com", "correct horse", "other horse"], ["a@example.com", "", ""]].each do |lines|
        expect(run_task("users:create", *lines).last).to be(false)
      end
      expect(User.count).to eq(0)
    end

    it "stops without input" do
      expect(run_task("users:create").last).to be(false)
    end
  end

  describe "users:password" do
    it "changes the password and ends every session" do
      user = create(:user)
      user.sessions.create!
      expect(run_task("users:password", "a new password", "a new password").last).to be(true)

      expect(user.reload.authenticate("a new password")).to eq(user)
      expect(Session.count).to eq(0)
    end

    it "keeps the password and sessions when refused" do
      user = create(:user)
      user.sessions.create!
      expect(run_task("users:password", "short", "short").last).to be(false)

      expect(user.reload.authenticate("correct horse")).to eq(user)
      expect(Session.count).to eq(1)
    end

    it "needs a user" do
      expect(run_task("users:password", "a new password", "a new password").last).to be(false)
    end
  end
end
