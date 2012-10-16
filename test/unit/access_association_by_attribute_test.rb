# encoding: utf-8

require 'test_helper'

class Test::Person < ActiveRecord::Base
  self.connection.create_table :test_people, :force => true do |t|
    t.string :name
  end
  set_table_name :test_people

  validates_uniqueness_of :name
end

class Test::Pet < ActiveRecord::Base
  extend AccessAssociationByAttribute

  self.connection.create_table :test_pets, :force => true do |t|
    t.integer :owner_id
    t.text    :name
    t.text    :animal
  end
  set_table_name :test_pets

  belongs_to :owner, :class_name => 'Test::Person'

  def self.setup_access
    access_association_by_attribute :owner, :name
  end
end

class AccessAssociationByAttributeTest < ActiveSupport::TestCase
  context 'access_association_by_attribute' do

    setup do
      @person1 = Test::Person.create! :name => 'Fred'
      @person2 = Test::Person.create! :name => 'Ali'

      @pet = Test::Pet.new :name => 'Spot', :animal => 'Dog', :owner => @person1
    end

    context 'on getting' do
      setup do
        Test::Pet.setup_access
      end

      should 'allow getting the attribute of the associated object' do
        assert_equal @pet.owner.name, @pet.owner_name
      end

      should 'return nil if association is nil' do
        @pet.owner = nil
        assert_equal nil, @pet.owner_name
      end

      should 'set an instance variable "@name" in object containing with default value' do
        @pet.owner_name
        assert_equal 'Fred', @pet.instance_variable_get('@owner_name')
      end
    end

    context 'on setting' do
      setup do
        Test::Pet.setup_access
      end

      should 'return set value on a get' do
        @pet.owner_name = 'Ali'
        assert_equal 'Ali', @pet.owner_name
      end

      should 'set an instance variable "@name" in object' do
        assert_false @pet.instance_variable_defined?('@owner_name')
        @pet.owner_name = 'A Name'
        assert_equal 'A Name', @pet.instance_variable_get('@owner_name')
      end

      should_eventually 'not raise when set value is not compatible type-wise with attribute being searched for' do
        @pet.owner_name = 1
        assert_nothing_raised do
          assert_equal false, @pet.valid?
        end

        assert ! @pet.errors[:name].blank?
      end
    end

    context 'on saving with valid assignment' do
      setup do
        Test::Pet.setup_access
      end

      should_eventually 'set association by given attribute value' do
        @pet.owner_name = 'Ali'
        @pet.save!
        @pet.reload
        assert_equal 'Ali', @pet.owner.name
      end

      should_eventually 'set correctly even if association was previously unset' do
        @pet.owner = nil
        @pet.owner_name = 'Ali'
        @pet.save!
        @pet.reload
        assert_equal 'Ali', @pet.owner.name
      end

      should_eventually 'allow unsetting association by passing nil' do
        @pet.owner_name = nil
        @pet.save!
        @pet.reload
        assert_equal nil, @pet.owner
      end

      should_eventually 'allow unsetting association by passing anything blank' do
        @pet.owner_name = ''
        @pet.save!
        @pet.reload
        assert_equal nil, @pet.owner
      end
    end

    context 'on saving with nonexistent parameter' do
      setup do
        Test::Pet.setup_access
        @pet.owner_name = 'Nonexistent'
        assert_false @pet.save
      end

      should 'cause validation errors if requested association object does not exist' do
        assert_include @pet.errors[:owner_name], "'Nonexistent' does not exist"
      end

      should 'still return incorrect value that caused error (just like setting a real attribute incorrectly would)' do
        assert_equal 'Nonexistent', @pet.owner_name
      end
    end

    should 'cause validation errors on saving with non-String parameter' do
      Test::Pet.setup_access
      @pet.owner_name = 55
      assert_false @pet.save
      assert_equal "'55' is invalid", @pet.errors[:owner_name].first
    end

    should 'not keep errors hanging around if assigned something invalid then valid again' do
      Test::Pet.setup_access
      @pet.owner_name = 'Nonexistent'
      @pet.owner_name = @person2.name
      assert @pet.valid?, @pet.errors.inspect
    end

    context 'attribute alias' do
      setup do
        class ::Test::Pet
          access_association_by_attribute :owner, :name, :attribute_alias => :full_name
        end
      end

      should 'allow access' do
        @pet.owner_full_name = @person2.name
        assert_equal @person2.name, @pet.owner_full_name
      end

      should_eventually 'be used in validation' do
        @pet.owner_full_name = 'Nonexistent'
        assert_false @pet.valid?
        assert ! @pet.errors['owner_full_name'].empty?
        assert @pet.errors['owner_name'].empty?
      end
    end

    context 'full alias' do
      setup do
        class ::Test::Pet
          access_association_by_attribute :owner, :name, :full_alias => :master
        end
      end

      should 'allow access' do
        @pet.master = @person2.name
        assert_equal @person2.name, @pet.master
      end

      should_eventually 'be used in validation' do
        @pet.master = 'Nonexistent'
        assert_false @pet.valid?
        assert ! @pet.errors['master'].empty?
        assert @pet.errors['owner_name'].empty?
      end
    end

    should_eventually 'reset all AABA attributes on reload' do
      class ::Test::Pet
        access_association_by_attribute :owner, :name
        access_association_by_attribute :owner, :name, :full_alias => :master
      end
      @pet.save!
      @pet.master; @pet.owner

      assert_equal @pet.owner.name, @pet.master
      assert_equal @pet.owner.name, @pet.owner_name

      @pet.master = 'Nonexistent'
      @pet.owner_name = 'Nonexistent'

      assert_false @pet.valid?

      @pet.reload

      assert_equal @pet.owner.name, @pet.master
      assert_equal @pet.owner.name, @pet.owner_name
      assert @pet.valid?, @pet.errors.inspect
    end

    should 'look up classes for associations within the current namespace' do
      class ::Test::Pet::Master < ActiveRecord::Base
        set_table_name 'test_people'
      end

      class ::Test::Pet
        belongs_to :master, :foreign_key => 'person_id'
        access_association_by_attribute :master, :name
      end

      master = ::Test::Pet::Master.create!(:name => 'Charles')
      pet = ::Test::Pet.create!(:master => master)

      assert_equal master, pet.master
    end

  end
end
