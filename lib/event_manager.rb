require 'erb'
require 'csv'
require 'google/apis/civicinfo_v2'
require 'date'
require 'time'

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone(phone)
  user_phone = phone.scan(/\d+/).join("")
  if user_phone.nil?
    puts user_phone
    puts "No number given"
  elsif user_phone.length == 10
    puts user_phone 
  elsif user_phone.length < 10
    puts "Bad number, too short #{user_phone}"
  elsif user_phone.length == 11 && user_phone[0] == '1'
    puts user_phone[1..-1]
  elsif user_phone.length > 11
    puts "Bad number, too long #{user_phone}"
  end
end

def count_frequency(array)
  array.max_by {|a| array.count(a)}
  # arr = Hash.new(0)
  # array.each { |a| arr[a]+=1}
  # array.uniq.map{ |n| array.count(n)}.max
end

puts 'Event Manager Initialized!'

contents_size = CSV.read('event_attendees.csv').length
j=0
hour_of_day = Array.new(contents_size)
contents = CSV.open(
  'event_attendees.csv', 
  headers: true,
  header_converters: :symbol
)





template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  phone = row[:homephone]
  reg_date = row[:regdate]
  
  reg_date_to_print = DateTime.strptime(reg_date, "%m/%d/%y %H:%M")
  hour_of_day[j] = reg_date_to_print.hour
  j+=1

  puts

  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  phone = clean_phone(row[:homephone])



  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end

puts "Most active hour is: #{count_frequency(hour_of_day)}"