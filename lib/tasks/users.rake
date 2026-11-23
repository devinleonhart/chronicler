require "io/console"

namespace :users do
  ask = lambda do |prompt|
    $stdout.print prompt
    $stdin.gets&.chomp || abort("No input")
  end

  # Passwords are not shown while typed.
  ask_password = lambda do
    passwords = ["Password: ", "Password again: "].map do |prompt|
      $stdin.tty? ? $stdin.getpass(prompt) : ask.call(prompt)
    end
    abort "The passwords differ" if passwords.uniq.size > 1
    passwords.first
  end

  save = lambda do |user|
    abort user.errors.full_messages.join("\n") unless user.save
    puts "Saved #{user.email_address}"
  end

  desc "Create the user, asking for an email address and password"
  task create: :environment do
    abort "A user already exists" if User.exists?

    email_address = ask.call("Email address: ")
    save.call(User.new(email_address:, password: ask_password.call))
  end

  desc "Change the user's password and end every session"
  task password: :environment do
    user = User.first || abort("There is no user")
    user.password = ask_password.call
    User.transaction do
      save.call(user)
      user.sessions.destroy_all
    end
  end
end
