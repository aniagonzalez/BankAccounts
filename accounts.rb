# BankAccounts
# Create a Bank module which will contain your Account class and any future bank account logic.

module Bank

  #A new account should be created with an ID and an initial balance
  class Account
    #Should be able to access the current balance of an account at any time.
    attr_reader :balance, :id
    def initialize(id, balance, open_date, its_owner = nil) #intialize owner to nil
      #A new account cannot be created with initial negative balance - this will raise an ArgumentError
      raise ArgumentError, "A new account cannot be created with initial negative balance." if balance < 0
      @id = id
      @balance = balance
      @open_date = open_date
      @owner_id = its_owner
      #@account_owner = owner #link this??
    end

    def self.all(file_path = "./support/accounts.csv")
      require 'CSV'
      all_accounts = []
      CSV.foreach(file_path, "r") do |line|

        its_owner = ""
        CSV.foreach("./support/account_owners.csv", "r") do |match|
          if match[0].to_s == line[0].to_s #if in the relaitonship file the owner id is equal to the owner
            its_owner = match[1] #send the account id into their_accounts array
          end
        end


        all_accounts << self.new(line[0].to_i, line[1].to_f, line[2], its_owner)
      end
      return all_accounts
    end

    def self.find(id)
      self.all.each do |account_inst|
        if account_inst.id.to_s == id.to_s
          return account_inst
        end
      end
    end

    # withdraw method that accepts a single parameter which represents the amount of money
    # that will be withdrawn. This method should return the updated account balance.
    def withdraw(amount)
      #withdraw method does not allow the account to go negative - Will puts a
      #warning message and then return the original un-modified balance
      if amount <= @balance
        @balance = @balance - amount
        return @balance
      else
        puts "WARNING: The amount requested is greater than the account's balance."
        return @balance
      end
    end

    # deposit method that accepts a single parameter which represents the amount of money
    # that will be deposited. This method should return the updated account balance.
    def deposit(amount)
      @balance = @balance + amount
      return @balance
    end

    def add_owner(id)
      @owner_id = id
    end
  end

  class SavingsAccount < Bank::Account
    attr_reader :balance, :id
    WITHDRAW_FEE = 2
    def initialize(id, balance, open_date, its_owner = nil)
      raise ArgumentError, "A new account cannot be created with initial negative balance." if balance < 10
      @id = id
      @balance = balance
      @open_date = open_date
      @owner_id = its_owner
      #@account_owner = owner #link this??
    end

    def withdraw(amount)
      if (amount + WITHDRAW_FEE) <= @balance
        new_balance = @balance - amount - WITHDRAW_FEE
        if new_balance < 10
          puts "WARNING: The account cannot go below $10. Withdrawal refused."
          return @balance
        else
          @balance = new_balance
          return @balance
        end
      else
        puts "WARNING: The amount requested plus the fee is greater than the account's balance."
        return @balance
      end
    end

    def add_interest(rate)
      interest = @balance * rate/100
      @balance = @balance + interest
      return interest
    end
  end

  class CheckingAccount < Account
    WITHDRAW_FEE = 1
    TRANSACTION_FEE = 2
    attr_reader :number_free_checks, :number_incurred_checks

    def initialize(id, balance, open_date, its_owner = nil)
      super
      @number_free_checks = 3
      @number_incurred_checks = 0
    end

    def withdraw(amount)
      if (amount + WITHDRAW_FEE) <= @balance
        @balance = @balance - amount - WITHDRAW_FEE
        return @balance
      else
        puts "WARNING: The amount requested plus the fee is greater than the account's balance."
        return @balance
      end
    end

    def withdraw_using_check(amount)
      #Determine if there is an incurred_fee: more than 3 checks, incurs in TRANSACTION_FEE
      if @number_free_checks <= 0
        incurred_fee = TRANSACTION_FEE
      else
        incurred_fee = 0
      end

      if (amount + incurred_fee) <= @balance
        new_balance = @balance - amount - incurred_fee
        if new_balance < -10
          puts "WARNING: The account cannot go below -$10. Check withdrawal refused."
          return @balance
        else
          @balance = new_balance
          @number_free_checks = @number_free_checks - 1
          @number_incurred_checks = @number_incurred_checks + 1
          return @balance
        end
      else
        puts "WARNING: The amount requested plus the incurred fee is greater than the account's balance."
        return @balance
      end
    end

    def reset_checks
      @number_free_checks = 3
    end
  end

  class MoneyMarketAccount < Account
    TRANSACTION_LIMIT = 6

    attr_reader :balance, :id, :transaction_count
    def initialize(id, balance, open_date, its_owner = nil)
      raise ArgumentError, "A new account cannot be created with initial balance lower than $10,000." if balance < 10000
      @id = id
      @balance = balance
      @open_date = open_date
      @owner_id = its_owner
      @transaction_count = 0
    end

    def withdraw(amount)
      #If a withdrawal causes the balance to go below $10,000, a fee of $100
      #is imposed and no more transactions are allowed until the balance is increased using a deposit transaction
      if @transaction_count < 6
        if balance < 10000
          puts "WARNING: No more transactions allowed until balance is increased above $10,000"
        else
          if amount <= @balance
            new_balance = @balance - amount
            if new_balance < 10000
              imposed_fee = 100
            else
              imposed_fee = 0
            end
            @balance = @balance - amount - imposed_fee
            @transaction_count = @transaction_count + 1
            if imposed_fee > 0
              puts "WARNING: The balance has gone below $10,000 and a fee of $100 was applied. No more transactions allowed until balance is increased."
            end
            return @balance

          else
            puts "WARNING: The amount requested is greater than the account's balance."
            return @balance
          end
        end
      else
        puts "The maximum number of transactions for the month has been reached. Withdrawal refused."
        return @balance
      end
    end #withdraw method end

    def deposit(amount)
      #A deposit performed to reach or exceed the minimum balance of $10,000
      #is not counted as part of the 6 transactions.
      if @balance < 10000
        @balance = @balance + amount
        puts "This transaction did not count towards your transaction count."
        return @balance

      else
        if @transaction_count < 6
          @balance = @balance + amount
          @transaction_count = @transaction_count + 1
          return @balance
        else
          puts "The maximum number of transactions for the month has been reached. Withdrawal refused."
          return @balance
        end #conditional for transaction_count end

      end # balance < 10000 conditional end
    end #deposit method end


    def reset_transactions
      @transaction_count = 0
    end

    def add_interest(rate)
      interest = @balance * rate/100
      @balance = @balance + interest
      return interest
    end


  end

  class Owner
    attr_reader :id
    def initialize(id, last_name, first_name, street_address, city, state, accounts = [])
      @id = id
      @last_name = last_name
      @first_name = first_name
      @street_address = street_address
      @city = city
      @state = state
      @accounts = accounts #store the owner account ids in an array
    end

    def self.all(file_path = "./support/owners.csv")
      require 'CSV'
      all_owners = []
      CSV.foreach(file_path, "r") do |line|

        their_accounts = []
        CSV.foreach("./support/account_owners.csv", "r") do |match|
          if match[1].to_s == line[0].to_s #if in the relaitonship file the owner id is equal to the owner
            their_accounts << match[0] #send the account id into their_accounts array
          end
        end

        all_owners << self.new(line[0], line[1], line[2], line[3], line[4], line[5], their_accounts)

      end
      return all_owners
    end

    def self.find(id)
      self.all.each do |owner_inst|
        if owner_inst.id.to_s == id.to_s
          return owner_inst
        end
      end
    end

  #  end
  end
end
