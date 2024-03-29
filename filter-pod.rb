#!/usr/bin/env ruby

require 'optparse'
require 'nokogiri'
require 'open-uri'
require 'date'

url = nil
include_filter = nil
exclude_filter = nil
item_path='//rss/channel/item'
field='title'
pod_link=nil
earliest_pub=nil
pod_title=nil
pod_image=nil

OptionParser.new do |parser|
	parser.on('-u', '--url URL') do |x|
		url = x
	end

	parser.on('-i', '--include-filter REGEX') do |x|
		include_filter = x
	end

	parser.on('-x', '--exclude-filter REGEX') do |x|
		exclude_filter = x
	end

	parser.on('', "--item-path XPATH (Default: %s )" % [item_path] ) do |x|
		item_path = x
	end

	parser.on('', "--filter-field FIELD (Default: %s)" % [field] ) do |x|
		field = "./%s" % [x]
	end

	parser.on('', '--earliest-pub-date DATE (Format: YYYY-MM-DD)' ) do |x|
		raise "Invalid date for --earliest-pub-date" if x !~ /20[0-9]{2}-[01][0-9]-[0-3][0-9]/
		earliest_pub = x
	end

	parser.on('-l', "--pod-link URL" % [field] ) do |x|
		pod_link = x
	end

	parser.on('', "--pod-title title" % [field] ) do |x|
		pod_title = x
	end

	parser.on('', "--pod-image URL" % [field] ) do |x|
		pod_image = x
	end

end.parse!

raise "URL required" if url.nil? || url === ""

MAX_ATTEMPTS = 3
attempts = MAX_ATTEMPTS

begin
	doc = Nokogiri::XML(URI.open(url, :read_timeout => 120))
rescue => e
	puts e
	attempts -= 1
	sleep ((MAX_ATTEMPTS - attempts) * 5 )
	retry if attempts > 0
	puts "Attempts expired."
	raise "Cannot reach podcast feed."
end

# https://filteredpods.s3.amazonaws.com/pods/images/extra_point_taken.jpg

if ! pod_title.nil?
	doc.xpath('//rss/channel/title').first.content = pod_title
	doc.xpath('//rss/channel/image/title').first.content = pod_title
end

if ! pod_image.nil?
	doc.xpath('//rss/channel/image/url').first.content = pod_image
	doc.xpath('//rss/channel/itunes:image').attr('href', pod_image)
end

if ! pod_link.nil?
	doc.xpath('//rss/channel/atom:link').attr('href', pod_link)
	doc.xpath('//rss/channel/link').first.content = pod_link
end

doc.xpath(item_path).each do |item|
	if !earliest_pub.nil? and Date.parse(item.xpath('pubDate').text).strftime('%Y-%m-%d') < earliest_pub
		item.remove
		next
	end

	if !include_filter.nil? and item.xpath(field).text !~ /#{include_filter}/i
		item.remove
		next
	end

	if !exclude_filter.nil? and item.xpath(field).text =~ /#{exclude_filter}/i
		item.remove
	end

	if ! pod_image.nil?
		item.xpath('itunes:image').attr('href', pod_image)
	end

end


puts doc.to_s.gsub(/^\s+\n/,'')
