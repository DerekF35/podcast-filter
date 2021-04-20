#!/usr/bin/env ruby

require 'optparse'
require 'nokogiri'
require 'open-uri'

url = nil
include_filter = nil
exclude_filter = nil
item_path='//rss/channel/item'
field='title'
pod_link=nil

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

	parser.on('l', "--pod-link URL" % [field] ) do |x|
		pod_link = x
	end

end.parse!

raise "URL required" if url.nil? || url === ""

doc = Nokogiri::XML(URI.open(url))

if ! pod_link.nil?
	doc.xpath('//rss/channel/atom:link').attr('href', pod_link)
	doc.xpath('//rss/channel/link').first.content = pod_link
end

doc.xpath(item_path).each do |item|
	if !include_filter.nil? and !item.xpath(field).text =~ /#{include_filter}/i
		item.remove
	end

	if !exclude_filter.nil? and item.xpath(field).text =~ /#{exclude_filter}/i
		item.remove
	end
end


puts doc.to_s
