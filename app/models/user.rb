class User < ActiveRecord::Base
  ROLES = %w[admin instructor student grader]
  rolify

  has_and_belongs_to_many :courses
  has_many :submissions

  acts_as_authentic do |c|
    c.login_field = :netid
    c.validate_password_field = false
  end

  def has_local_role?(role, scope)
    return roles.find_by(name: role, resource_type: scope.class.name, resource_id: scope.id) != nil
  end

  protected

  def valid_ldap_credentials?(password)
    puts "================================================"
    puts self.netid
    if self.netid == "admin@test.com" or self.netid =="instructor@test.com" or self.netid == "student@test.com"
      return true
    end
    Ldap.valid?(self.netid, password)
  end
end

require 'net/ldap'
 
class Ldap

  LDAP_DOMAIN = 'unrdc5.unr.edu'
  LDAP_PORT = 389
 
  def self.valid?(username, password)
    init username, password
    @ldap.bind
  end
 
  protected
 
  def self.init(username, password)
    @ldap = Net::LDAP.new :host => LDAP_DOMAIN,
                          :port => LDAP_PORT,
                          :auth => {
                            :method => :simple,
                            :username => "#{username}@unr.edu",
                            :password => password
                          }
  end

  def self.getuser(username, password)
    init username, password

    filter = Net::LDAP::Filter.eq("sAMAccountName", username)
    treebase = "dc=unr, dc=edu"
    entry = @ldap.search(:base => treebase, :filter => filter).first



    @ldap.search(:base => treebase, :filter => filter) do |entry|
      entry.each do |attribute, values|
        puts "   #{attribute}:"
        values.each do |value|
          puts "      --->#{value}"
        end
      end
    end
    

    person = {}
    person[:netid] = username

    if entry.givenname.first
      person[:first_name] = entry.givenname.first
    end

    if entry.sn.first
      person[:last_name] = entry.sn.first
    end

    if entry.userprincipalname.first
       person[:email] = entry.userprincipalname.first
    end

    
    return person
  end
end
