require 'test/unit'
require 'beanstream'
require 'shoulda'

module Beanstream
  class ProfilesAPITest < Test::Unit::TestCase
    setup do
      Beanstream.merchant_id = "300200578"
      Beanstream.payments_api_key = "4BaD82D9197b4cc4b70a221911eE9f70"
      Beanstream.profiles_api_key = "D97D3BE1EE964A6193D17A571D9FBC80"
    end

    should "make profiles url be the same" do
      assert_equal("/api/v1/profiles", ProfilesAPI.new.profile_url())
    end

    should "make profiles/cards url be the same" do
      assert_equal("/api/v1/profiles/cards", ProfilesAPI.new.profile_cards_url())
    end
  end

  class ProfilesAPIIntegrationTest < Test::Unit::TestCase
    setup do
      Beanstream.merchant_id = "300200578"
      Beanstream.payments_api_key = "4BaD82D9197b4cc4b70a221911eE9f70"
      Beanstream.profiles_api_key = "D97D3BE1EE964A6193D17A571D9FBC80"
      @profile = Beanstream.ProfilesAPI.create_profile(
      {
        :billing => {
          :name => "Hilary Test",
          :address_line1 => "123 Fake St.",
          :city => "Victoria",
          :province => "BC",
          :country => "CA",
          :postal_code => "v1v2v2",
          :phone_number => "12505551234",
          :email_address => "fake@example.com"
        }
      })

      @card1 = {
        :card => {
          :name => "Hilary Test",
          :number => "4030000010001234",
          :expiry_month => "07",
          :expiry_year => "22",
          :cvd => "123"
        }
      }

      @card2 = {
        :card => {
          :name => "John Doe",
          :number => "5100000010001004",
          :expiry_month => "12",
          :expiry_year => "14",
          :cvd => "123"
        }
      }
    end

    # Profile CREATE with CARD
    should "have successfully created a profile with credit card" do
      begin
        profile = Beanstream.ProfilesAPI.getCreateProfileWithCardTemplate()
        profile[:card][:name] = "Bob Test"
        profile[:card][:number] = "4030000010001234"
        profile[:card][:expiry_month] ="07"
        profile[:card][:expiry_year] = "22"
        profile[:card][:cvd] = "123"
        profile[:billing][:name] = "Bob Test"
        profile[:billing][:address_line1] = "123 Fake St."
        profile[:billing][:city] = "Victoria"
        profile[:billing][:province] = "BC"
        profile[:billing][:country] = "CA"
        profile[:billing][:postal_code] = "v1v2v2"
        profile[:billing][:phone_number] = "12505551234"
        profile[:billing][:email_address] = "fake@example.com"

        result = Beanstream.ProfilesAPI.create_profile(profile)

        assert(ProfilesAPI.profile_successfully_created(result))
        profile_id = result['customer_code']
        puts "Created profile with ID: #{profile_id}"
      rescue BeanstreamException => ex
        assert(false)
      end
    end

    # Profile CREATE with TOKEN
    should "have successfully created a profile with token" do
      begin
        token = Beanstream.PaymentsAPI.get_legato_token(
          {
            :number => "4030000010001234",
            :expiry_month => "07",
            :expiry_year => "22",
            :cvd => "123"
          }
        )
        puts "token result: #{token}"
        assert(token != nil)

        profile = Beanstream.ProfilesAPI.getCreateProfileWithTokenTemplate()
        profile[:token][:name] = "Bob Test"
        profile[:token][:code] = token
        profile[:billing][:name] = "Bob Test"
        profile[:billing][:address_line1] = "123 Fake St."
        profile[:billing][:city] = "Victoria"
        profile[:billing][:province] = "BC"
        profile[:billing][:country] = "CA"
        profile[:billing][:postal_code] = "v1v2v2"
        profile[:billing][:phone_number] = "12505551234"
        profile[:billing][:email_address] = "fake@example.com"

        result = Beanstream.ProfilesAPI.create_profile(profile)

        assert(ProfilesAPI.profile_successfully_created(result))
        profile_id = result['customer_code']
        puts "Created profile with ID: #{profile_id}"
      rescue BeanstreamException => ex
        assert(false)
      end
    end

    # Profile DELETE
    should "have successfully deleted a profile" do
      Beanstream.merchant_id = "300200578"
      Beanstream.profiles_api_key = "D97D3BE1EE964A6193D17A571D9FBC80"

      result = Beanstream.ProfilesAPI.create_profile(
      {
        :card => {
          :name => "Jill Test",
          :number => "4030000010001234",
          :expiry_month => "07",
          :expiry_year => "22",
          :cvd => "123"
        },
        :billing => {
          :name => "Jill Test",
          :address_line1 => "123 Fake St.",
          :city => "Victoria",
          :province => "BC",
          :country => "CA",
          :postal_code => "v1v2v2",
          :phone_number => "12505551234",
          :email_address => "fake@example.com"
        }
      })
      assert(ProfilesAPI.profile_successfully_created(result))
      profile_id = result['customer_code']
      puts "Created profile with ID: #{profile_id}"

      # now delete the profile
      result = Beanstream.ProfilesAPI.delete_profile(profile_id)
      assert(ProfilesAPI.profile_successfully_deleted(result))
      puts "Deleted profile #{result['customer_code']}"
    end

    # Profile GET
    should "have successfully retrieved a profile" do
      Beanstream.merchant_id = "300200578"
      Beanstream.profiles_api_key = "D97D3BE1EE964A6193D17A571D9FBC80"

      result = Beanstream.ProfilesAPI.create_profile(
      {
        :card => {
          :name => "Jill Test",
          :number => "4030000010001234",
          :expiry_month => "07",
          :expiry_year => "22",
          :cvd => "123"
        },
        :billing => {
          :name => "Jill Test",
          :address_line1 => "123 Fake St.",
          :city => "Victoria",
          :province => "BC",
          :country => "CA",
          :postal_code => "v1v2v2",
          :phone_number => "12505551234",
          :email_address => "fake@example.com"
        }
      })
      assert(ProfilesAPI.profile_successfully_created(result))
      profile_id = result['customer_code']
      puts "Created profile with ID: #{profile_id}"

      # now get that profile
      result = Beanstream.ProfilesAPI.get_profile(profile_id)
      assert(result != nil)
      assert(result['billing']['name'] == "Jill Test")

      Beanstream.ProfilesAPI.delete_profile(profile_id) #delete it to clean up
    end

    # Profile UPDATE
    should "have successfully updated a profile" do
      Beanstream.merchant_id = "300200578"
      Beanstream.profiles_api_key = "D97D3BE1EE964A6193D17A571D9FBC80"

      result = Beanstream.ProfilesAPI.create_profile(
      {
        :card => {
          :name => "Hilary Test",
          :number => "4030000010001234",
          :expiry_month => "07",
          :expiry_year => "22",
          :cvd => "123"
        },
        :billing => {
          :name => "Hilary Test",
          :address_line1 => "123 Fake St.",
          :city => "Victoria",
          :province => "BC",
          :country => "CA",
          :postal_code => "v1v2v2",
          :phone_number => "12505551234",
          :email_address => "fake@example.com"
        }
      })
      assert(ProfilesAPI.profile_successfully_created(result))
      profile_id = result['customer_code']
      puts "Created profile with ID: #{profile_id}"

      # now get that profile
      profile1 = Beanstream.ProfilesAPI.get_profile(profile_id)
      assert(profile1 != nil)
      assert(profile1['billing']['name'] == "Hilary Test")
      puts "\n\nRetrieved Profile 1:\n\n #{profile1}"

      # update profile
      profile1['billing']['name'] = "gizmo test"
      profile1['language'] = "en"
      profile1['comments'] = "test profile"
      profile1['custom']['ref1'] = "i wish"
      profile1['custom']['ref2'] = "i was"
      profile1['custom']['ref3'] = "an oscar"
      profile1['custom']['ref4'] = "mayer"
      profile1['custom']['ref5'] = "weiner"
      result = Beanstream.ProfilesAPI.update_profile(profile1)

      # get profile again and check the updates
      profile2 = Beanstream.ProfilesAPI.get_profile(profile_id)
      puts "\n\nRetrieved Profile 2:\n\n #{profile2}"
      assert(profile2 != nil)
      assert(profile2['billing']['name'] == "gizmo test")
      assert(profile2['language'] == "en")
      assert(profile2['custom']['ref1'] == "i wish")
      assert(profile2['custom']['ref2'] == "i was")
      assert(profile2['custom']['ref3'] == "an oscar")
      assert(profile2['custom']['ref4'] == "mayer")
      assert(profile2['custom']['ref5'] == "weiner")

      Beanstream.ProfilesAPI.delete_profile(profile_id) #delete it to clean up
    end

    should 'Successfully Add Card' do
      insert_card = Beanstream.ProfilesAPI.add_profile_card(@profile,@card1)
      # Retrieve Profile  again to check if card added
      profile2 = Beanstream.ProfilesAPI.get_profile(@profile['customer_code'])
      assert(profile2['card'])
      assert(insert_card['message']== 'Operation Successful')
    end

    should 'Successfully get Card' do
      add_card = Beanstream.ProfilesAPI.add_profile_card(@profile,@card1)
      card = Beanstream.ProfilesAPI.get_profile_card(@profile)
      assert(card)
      assert(card['message']== 'Operation Successful')
    end

    should 'successfully update card' do
      # Create profile with card 1
      insert_card = Beanstream.ProfilesAPI.add_profile_card(@profile,@card2)
      # Update profile with card 2
      update_card = Beanstream.ProfilesAPI.update_profile_card(@profile,1,@card1)
      profile2 = Beanstream.ProfilesAPI.get_profile(@profile['customer_code'])
      assert(update_card['message']== 'Operation Successful')
    end

    should 'successfully delete card' do
      # Create profile with card 1
      insert_card = Beanstream.ProfilesAPI.add_profile_card(@profile,@card2)
      # delete card from profile
      delete_card = Beanstream.ProfilesAPI.delete_profile_card(@profile,1)
      assert(delete_card['message']== 'Operation Successful')
    end

    # Profile PAYMENT and PRE_AUTH
    should "have successfully made payments with a profile" do
      profile_id = ""
      begin
        result = Beanstream.ProfilesAPI.create_profile(
        {
          :card => {
            :name => "Bob Test",
            :number => "4030000010001234",
            :expiry_month => "07",
            :expiry_year => "22",
            :cvd => "123"
          },
          :billing => {
            :name => "Bob Test",
            :address_line1 => "123 Fake St.",
            :city => "Victoria",
            :province => "BC",
            :country => "CA",
            :postal_code => "v1v2v2",
            :phone_number => "12505551234",
            :email_address => "fake@example.com"
          }
        })
        assert(ProfilesAPI.profile_successfully_created(result))
        profile_id = result['customer_code']
        puts "Created profile with ID: #{profile_id}"
      rescue BeanstreamException => ex
        puts "Error: #{ex.user_facing_message()}"
        assert(false)
      end

      begin
        # payment
        profile_payment = Beanstream.PaymentsAPI.getProfilePaymentRequestTemplate()
        profile_payment[:payment_profile][:customer_code] = profile_id
        profile_payment[:amount] = 77.50
        result = Beanstream.PaymentsAPI.make_payment(profile_payment)
      rescue BeanstreamException => ex
        puts "Error: #{ex.user_facing_message()}"
        assert(false) #declined
      end

      begin
        # pre-auth
        profile_payment = Beanstream.PaymentsAPI.getProfilePaymentRequestTemplate()
        profile_payment[:amount] = 80
        profile_payment[:payment_profile][:customer_code] = profile_id
        profile_payment[:payment_profile][:complete] = false #false for pre-auth
        result = Beanstream.PaymentsAPI.make_payment(profile_payment)

        # complete pre-auth
        result = Beanstream.PaymentsAPI.complete_preauth(result['id'], 40.50)
        puts "completion result: #{result}"
        assert(PaymentsAPI.payment_approved(result))
      rescue BeanstreamException => ex
        puts "Error: #{ex.user_facing_message()}"
        assert(false) # declined
      end
    end
  end
end
