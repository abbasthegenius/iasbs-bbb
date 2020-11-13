#!/usr/bin/ruby
# encoding: UTF-8

#
# BigBlueButton open source conferencing system - http://www.bigbluebutton.org/
#
# Copyright (c) 2012 BigBlueButton Inc. and by respective authors (see below).
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU Lesser General Public License as published by the Free
# Software Foundation; either version 3.0 of the License, or (at your option)
# any later version.
#
# BigBlueButton is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
# details.
#
# You should have received a copy of the GNU Lesser General Public License along
# with BigBlueButton; if not, see <http://www.gnu.org/licenses/>.
#

require "trollop"
require "jwt"
require "java_properties"
require 'rubygems'
require 'fileutils'
require 'date'
require 'json'
require 'yaml'
require 'cgi'

def unifying(st)
  st = st.gsub("`", "\\\\`")
  st
end

require File.expand_path('../../../lib/recordandplayback', __FILE__)

logger = Logger.new("/var/log/bigbluebutton/post_publish.log", 'weekly' )
logger.level = Logger::INFO
BigBlueButton.logger = logger
opts = Trollop::options do
  opt :meeting_id, "Meeting id to archive", :type => String
end
meeting_id = opts[:meeting_id]
BigBlueButton.logger.info("Recording Download for [#{meeting_id}] starts")
begin  
  props = YAML::load(File.open('bigbluebutton.yml'))
  src = "#{props['published_dir']}/presentation/"
  playback_dir = "#{props['download_dir']}/playback"
  published_file = "#{src}#{meeting_id}"
  class_date = meeting_id.split('-')
  if class_date.length() < 2
      BigBlueButton.logger.info("Error in generating zip! Class Date is incorrect: '#{meeting_id}' ")
      exit
  end
  base = "#{props['download_dir']}/#{class_date[0]}"
  target_dir = base
  if not FileTest.directory?(target_dir)
    FileUtils.mkdir_p target_dir
  end
  class_date = Time.at(class_date[1].to_i / 1000).strftime("%Y-%m-%d_%H-%M")
  if not FileTest.exist?("#{published_file}/metadata.xml")
      BigBlueButton.logger.info("Error in generating zip! metadat.xml does not exist: '#{meeting_id}' ")
      exit
  end
  doc = File.open("#{published_file}/metadata.xml") { |f| Nokogiri::XML(f) }
  class_name = "#{doc.at_xpath('/recording/meta/meetingName').content.gsub(' ','_')}_#{class_date}"
  if FileTest.exist?("#{target_dir}/#{class_name}.zip")
      system ("mv '#{base}/#{class_name}.zip' '#{published_file}/'")
      exit
  end
  
  target_dir = "#{target_dir}/#{class_name}"
  FileUtils.mkdir_p target_dir
  FileUtils.cp_r("#{playback_dir}/play.html", target_dir)
  FileUtils.cp_r("#{playback_dir}/res", target_dir)

  value_js = File.open("#{target_dir}/res/lib/values.js", "w")
  value_js.puts "const metadataXML = `#{unifying(doc.root.to_s)}`;"

  doc = File.open("#{published_file}/shapes.svg") { |f| Nokogiri::XML(f) }
  value_js.puts "const shapesSVG = `#{unifying(doc.root.to_s)}`;"

  doc = File.open("#{published_file}/panzooms.xml") { |f| Nokogiri::XML(f) }
  value_js.puts "const panzoomsXML = `#{unifying(doc.root.to_s)}`;"
  
  doc = File.open("#{published_file}/cursor.xml") { |f| Nokogiri::XML(f) }
  value_js.puts "const cursorXML = `#{unifying(doc.root.to_s)}`;"
  
  doc = File.open("#{published_file}/deskshare.xml") { |f| Nokogiri::XML(f) }
  value_js.puts "const deskshareXML = `#{unifying(doc.root.to_s)}`;"

  doc = File.open("#{published_file}/slides_new.xml") { |f| Nokogiri::XML(f) }
  value_js.puts "const chatXML = `#{unifying(doc.root.to_s)}`;"

  doc = File.read("#{published_file}/presentation_text.json")
  value_js.puts "const textJSON = #{doc.to_s};"

  doc = File.read("#{published_file}/captions.json")
  value_js.puts "const captionsJSON = #{doc.to_s};"

  value_js.close

  hasVideo = "false"
  hasDesk = "false"

  if FileTest.exist?("#{published_file}/video/webcams.webm") ||  FileTest.exist?("#{published_file}/video/webcams.mp4")
      hasVideo = "true"
  end

  if FileTest.exist?("#{published_file}/deskshare/deskshare.webm") || FileTest.exist?("#{published_file}/deskshare/deskshare.mp4")
      hasDesk = "true"
  end

  doc = File.read("#{target_dir}/res/playback.js")
  doc = doc.to_s.gsub('hasVideo = false', "hasVideo = #{hasVideo}")
  doc = doc.gsub('hasDeskshare = false', "hasDeskshare = #{hasDesk}")
  f = File.open("#{target_dir}/res/playback.js", "w") 
  f.puts doc
  f.close

  FileUtils.mkdir_p "#{target_dir}/res/files"
  if hasVideo == "true"
    FileUtils.cp_r("#{published_file}/video", "#{target_dir}/res/files")
  end
  if hasDesk == "true"
    FileUtils.cp_r("#{published_file}/deskshare", "#{target_dir}/res/files")
  end

  FileUtils.cp_r("#{published_file}/presentation", "#{target_dir}/res/files")

  BigBlueButton.logger.info("Creating Zip File")

  system("cd #{base} && zip -rmv -9 '#{class_name}.zip' '#{class_name}'")

  system("mv '#{base}/#{class_name}.zip' '#{published_file}/'")

  system("rm -r '#{base}'")
rescue => e
  BigBlueButton.logger.info("Rescued")
  BigBlueButton.logger.info(e.to_s)
end

BigBlueButton.logger.info("Recording Download ends")

exit 0
