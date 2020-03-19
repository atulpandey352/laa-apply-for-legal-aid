# rake file to assist in adding beta users to the two config files
#
# Simply create a list of new users one per line in a text file, and put the filename in NEW_USERS_FILE
#
# After you run the rake taks, you will have two new config files with UPDATED in their name, so that you
# can compare before replacing the original with the updated ones.
#
namespace :tranche do
  task maker: :environment do
    new_users = File.read(Rails.root.joins('add_tranche_users.txt')).split("\n")

    whitelisted_users = YAML.load_file(Rails.root.join('helm_deploy/apply-for-legal-aid/whitelisted_users.yaml'))
    beta_test_users = YAML.load_file(Rails.root.join('config/encrypted_private_beta_users.yml'))

    new_users.each do |user|
      uri = URI("https://ccms-pda.legalservices.gov.uk/api/providerDetails/#{user.upcase}")
      response = Net::HTTP.get(uri)
      hash = JSON.parse(response)
      if hash.key?('error')
        puts ">>>>>>>> User #{user} not found <<<<<<<<<"
      else
        contact_hash = hash['contacts'].detect { |h| h['name'] == user.upcase }
        whitelisted_users << user.upcase

        beta_test_users[user.upcase] = contact_hash['id']
      end
    end

    File.open('helm_deploy/apply-for-legal-aid/whitelisted_users.UPDATED.yaml', 'w') do |fp|
      fp.puts whitelisted_users.sort.to_yaml
    end

    File.open('config/encrypted_private_beta_users.UPDATED.yml', 'w') do |fp|
      fp.puts beta_test_users.to_yaml
    end
  end
end